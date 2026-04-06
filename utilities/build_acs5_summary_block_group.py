#!/usr/bin/env python3

import argparse
import csv
import io
import re
import shutil
import subprocess
import sys
import time
import urllib.error
import urllib.request
import zipfile
from pathlib import Path


REQUEST_HEADERS = {
    "User-Agent": "Mozilla/5.0 (compatible; fairadi-acs5-summary-builder/1.0; +https://github.com/)",
    "Accept": "*/*",
}

SUPPORTED_YEARS = {2010, 2011, 2012}
SUMMARY_RANGE_ANNOTATIONS = {
    "B19013_001": {
        "2499": "2,500-",
        "250001": "250,000+",
    },
    "B25064_001": {
        "99": "100-",
        "2001": "2,000+",
        "3501": "3,500+",
    },
    "B25077_001": {
        "9999": "10,000-",
        "2000001": "2,000,000+",
    },
    "B25088_001": {
        "99": "100-",
        "4001": "4,000+",
    },
    "B25088_002": {
        "99": "100-",
        "4001": "4,000+",
    },
    "B25088_003": {
        "99": "100-",
        "4001": "4,000+",
    },
}
GEO_HEADER = [
    "FILEID",
    "STUSAB",
    "SUMLEVEL",
    "COMPONENT",
    "LOGRECNO",
    "REGION",
    "DIVISION",
    "STATECE",
    "STATE",
    "COUNTY",
    "COUSUB",
    "PLACE",
    "TRACT",
    "BLKGRP",
    "CONCIT",
    "AIANHH",
    "AIANHHFP",
    "AIHHTLI",
    "AITSCE",
    "AITS",
    "ANRC",
    "CBSA",
    "METDIV",
    "MACC",
    "MEMI",
    "NECTA",
    "CNECTA",
    "NECTADIV",
    "BLANK",
    "CDCURR",
    "SLDU",
    "SLDL",
    "SUBMCD",
    "SDELM",
    "SDSEC",
    "SDUNI",
    "PUMA5",
    "BTTR",
    "BTBG",
    "NAME",
    "LSAD",
    "PARTFLAG",
    "UGA",
    "STATENS",
    "COUNTYNS",
    "COUSUBNS",
    "PLACENS",
    "CONCITNS",
    "AIANHHNS",
    "AITSNS",
    "ANRCNS",
    "SUBMCDNS",
    "AIANHHSC",
    "CSA",
    "CBSANSC",
    "METDIVNS",
    "NECTANSC",
    "NECTADIVNS",
    "CNECTANSC",
    "NAME_FULL",
    "GEOID",
]


def log(message: str) -> None:
    print(message, file=sys.stderr, flush=True)


def read_fips_states(path: Path) -> dict[str, str]:
    with path.open(newline="", encoding="utf-8") as src:
        return {row["state"]: row["name"] for row in csv.DictReader(src)}


def normalize_state_name(name: str) -> str:
    parts = re.findall(r"[A-Za-z0-9]+", name)
    return "".join(part[:1].upper() + part[1:] for part in parts)


def templates_url(year: int) -> str:
    if year == 2010:
        return f"https://www2.census.gov/programs-surveys/acs/summary_file/{year}/data/{year}_5yr_SummaryFileTemplates.zip"
    return f"https://www2.census.gov/programs-surveys/acs/summary_file/{year}/data/{year}_5yr_Summary_FileTemplates.zip"


def state_zip_url(year: int, state_name: str) -> str:
    return (
        f"https://www2.census.gov/programs-surveys/acs/summary_file/{year}/data/5_year_by_state/"
        f"{state_name}_Tracts_Block_Groups_Only.zip"
    )


def download(url: str, output: Path, retries: int = 5, timeout: int = 600) -> None:
    output.parent.mkdir(parents=True, exist_ok=True)
    tmp = output.with_suffix(output.suffix + ".tmp")
    if output.exists() and output.stat().st_size > 0:
        return
    last_error: Exception | None = None
    for attempt in range(retries):
        try:
            if shutil.which("curl"):
                subprocess.run(
                    [
                        "curl",
                        "--silent",
                        "--show-error",
                        "--location",
                        "--fail-with-body",
                        "--retry",
                        "5",
                        "--retry-delay",
                        "2",
                        "--retry-all-errors",
                        "--max-time",
                        str(timeout),
                        "--user-agent",
                        REQUEST_HEADERS["User-Agent"],
                        "--header",
                        f"Accept: {REQUEST_HEADERS['Accept']}",
                        url,
                        "--output",
                        str(tmp),
                    ],
                    check=True,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE,
                    text=True,
                )
            else:
                request = urllib.request.Request(url, headers=REQUEST_HEADERS)
                with urllib.request.urlopen(request, timeout=timeout) as response, tmp.open("wb") as dst:
                    while True:
                        chunk = response.read(1024 * 1024)
                        if not chunk:
                            break
                        dst.write(chunk)
            tmp.replace(output)
            return
        except (subprocess.CalledProcessError, urllib.error.URLError, TimeoutError, OSError) as exc:
            last_error = exc
            tmp.unlink(missing_ok=True)
            if attempt + 1 == retries:
                break
            time.sleep(2 * (attempt + 1))
    assert last_error is not None
    raise last_error


def sequence_variables(templates_zip: Path, sequence_member: str) -> list[str]:
    text = subprocess.check_output(["strings", "-"], input=zipfile.ZipFile(templates_zip).read(sequence_member))
    decoded = text.decode("latin-1", errors="ignore")
    values = []
    seen = set()
    for match in re.finditer(r"\b([BC]\d{5}[A-Z]?_\d{3})[A-Z]?\b", decoded):
        value = match.group(1)
        if value in seen:
            continue
        seen.add(value)
        values.append(value)
    return values


def template_sequence_and_vars(templates_zip: Path, table: str) -> tuple[str, list[str], list[int]]:
    pattern = re.compile(rf"\b({re.escape(table)}_\d{{3}})[A-Z]?\b")
    with zipfile.ZipFile(templates_zip) as zf:
        for name in sorted(zf.namelist()):
            if not name.startswith("Seq") or not name.endswith(".xls"):
                continue
            strings = subprocess.check_output(["strings", "-"], input=zf.read(name))
            text = strings.decode("latin-1", errors="ignore")
            if not pattern.search(text):
                continue
            all_vars = sequence_variables(templates_zip, name)
            wanted = [var for var in all_vars if var.startswith(f"{table}_")]
            positions = [idx for idx, var in enumerate(all_vars) if var.startswith(f"{table}_")]
            if wanted:
                seq_match = re.search(r"Seq(\d+)\.xls$", name)
                if seq_match is None:
                    raise ValueError(f"unexpected summary-file template filename: {name}")
                return f"{int(seq_match.group(1)):04d}", wanted, positions
    raise KeyError(f"could not find summary-file template mapping for {table}")


def state_zip_members(state_zip: Path) -> tuple[str, str, str]:
    with zipfile.ZipFile(state_zip) as zf:
        geo_name = next(
            name
            for name in zf.namelist()
            if name.startswith("g") and (name.endswith(".csv") or name.endswith(".txt"))
        )
        sample_est = next(name for name in zf.namelist() if name.startswith("e") and name.endswith(".txt"))
        sample_moe = next(name for name in zf.namelist() if name.startswith("m") and name.endswith(".txt"))
    return geo_name, sample_est, sample_moe


def seq_member_name(prefix_member: str, seq: str) -> str:
    match = re.match(r"^([em]\d{4}\d[a-z]{2})\d{4}000\.txt$", prefix_member)
    if match is None:
        raise ValueError(f"unexpected summary-file sequence filename: {prefix_member}")
    return f"{match.group(1)}{seq}000.txt"


def read_block_group_geography(state_zip: Path) -> dict[str, dict[str, str]]:
    geo_name, _, _ = state_zip_members(state_zip)
    geo: dict[str, dict[str, str]] = {}
    with zipfile.ZipFile(state_zip) as zf, zf.open(geo_name) as src:
        if geo_name.endswith(".csv"):
            reader = csv.reader(io.TextIOWrapper(src, encoding="latin-1", newline=""))
            for row in reader:
                if len(row) < 50:
                    continue
                if row[2] != "150" or row[3] != "00":
                    continue
                logrecno = row[4]
                geo[logrecno] = {
                    "GEO_ID": row[48],
                    "NAME": row[49],
                    "state": row[9],
                    "county": row[10],
                    "tract": row[13],
                    "block group": row[14],
                }
        else:
            for raw in io.TextIOWrapper(src, encoding="latin-1", newline=""):
                line = raw.rstrip("\n")
                if len(line) < 219:
                    continue
                if line[8:11] != "150" or line[11:13] != "00":
                    continue
                logrecno = line[13:20]
                geo[logrecno] = {
                    "GEO_ID": line[178:198].strip(),
                    "NAME": line[218:].strip(),
                    "state": line[25:27],
                    "county": line[27:30],
                    "tract": line[40:46],
                    "block group": line[46:47],
                }
    return geo


def read_sequence_rows(state_zip: Path, sequence: str) -> tuple[dict[str, list[str]], dict[str, list[str]]]:
    _, sample_est, sample_moe = state_zip_members(state_zip)
    est_name = seq_member_name(sample_est, sequence)
    moe_name = seq_member_name(sample_moe, sequence)
    est: dict[str, list[str]] = {}
    moe: dict[str, list[str]] = {}
    with zipfile.ZipFile(state_zip) as zf:
        with zf.open(est_name) as src:
            reader = csv.reader(io.TextIOWrapper(src, encoding="latin-1", newline=""))
            for row in reader:
                est[row[5]] = row[6:]
        with zf.open(moe_name) as src:
            reader = csv.reader(io.TextIOWrapper(src, encoding="latin-1", newline=""))
            for row in reader:
                moe[row[5]] = row[6:]
    return est, moe


def build_rows(
    geo: dict[str, dict[str, str]],
    est: dict[str, list[str]],
    moe: dict[str, list[str]],
    variables: list[str],
    positions: list[int],
) -> tuple[list[str], list[dict[str, str]]]:
    fieldnames: list[str] = []
    for var in variables:
        fieldnames.extend([f"{var}E", f"{var}EA", f"{var}M", f"{var}MA"])
    fieldnames.extend(["GEO_ID", "NAME", "state", "county", "tract", "block group"])

    rows: list[dict[str, str]] = []
    for logrecno in sorted(geo, key=lambda x: (
        geo[x]["state"],
        geo[x]["county"],
        geo[x]["tract"],
        geo[x]["block group"],
    )):
        if logrecno not in est or logrecno not in moe:
            continue
        row = {}
        for idx, var in enumerate(variables):
            pos = positions[idx]
            estimate = est[logrecno][pos]
            annotation = SUMMARY_RANGE_ANNOTATIONS.get(var, {}).get(estimate)
            moe_value = moe[logrecno][pos]

            row[f"{var}E"] = estimate
            row[f"{var}EA"] = annotation or "null"
            row[f"{var}M"] = "-333333333" if annotation and moe_value == "." else moe_value
            row[f"{var}MA"] = "***" if annotation else "null"
        row.update(geo[logrecno])
        rows.append(row)

    return fieldnames, rows


def write_gzip_csv(output: Path, fieldnames: list[str], rows: list[dict[str, str]]) -> None:
    import gzip

    output.parent.mkdir(parents=True, exist_ok=True)
    with gzip.open(output, "wt", encoding="utf-8", newline="") as dst:
        writer = csv.DictWriter(dst, fieldnames=fieldnames, quoting=csv.QUOTE_MINIMAL, lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--year", required=True, type=int)
    parser.add_argument("--state", required=True)
    parser.add_argument("--table", required=True)
    parser.add_argument("--states-csv", required=True, type=Path)
    parser.add_argument("--cache-dir", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    if args.year not in SUPPORTED_YEARS:
        raise SystemExit(f"summary-file importer only supports {sorted(SUPPORTED_YEARS)}")

    state_names = read_fips_states(args.states_csv)
    if args.state not in state_names:
        raise SystemExit(f"unknown state FIPS {args.state}")

    state_name = normalize_state_name(state_names[args.state])
    state_zip = args.cache_dir / str(args.year) / f"{state_name}_Tracts_Block_Groups_Only.zip"
    templates_zip = args.cache_dir / str(args.year) / Path(templates_url(args.year)).name

    log(f" summary file state zip: {state_zip.name}")
    download(state_zip_url(args.year, state_name), state_zip)
    log(f" summary file templates: {templates_zip.name}")
    download(templates_url(args.year), templates_zip)

    seq, variables, positions = template_sequence_and_vars(templates_zip, args.table)
    log(f" table {args.table} uses sequence {seq} with {len(variables)} variables")

    geo = read_block_group_geography(state_zip)
    est, moe = read_sequence_rows(state_zip, seq)
    fieldnames, rows = build_rows(geo, est, moe, variables, positions)
    write_gzip_csv(args.output, fieldnames, rows)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
