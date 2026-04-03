#!/usr/bin/env python3

import argparse
import csv
import html.parser
import re
import shutil
import subprocess
import sys
import tempfile
import time
import urllib.error
import urllib.request
import zipfile
from pathlib import Path

REQUEST_HEADERS = {
    "User-Agent": "Mozilla/5.0 (compatible; fairadi-fips-builder/1.0; +https://github.com/)",
    "Accept": "*/*",
}
REQUEST_PAUSE_SECONDS = 0.5


SUPPORTED_STATE_FIPS = {
    "01",
    "02",
    "04",
    "05",
    "06",
    "08",
    "09",
    "10",
    "11",
    "12",
    "13",
    "15",
    "16",
    "17",
    "18",
    "19",
    "20",
    "21",
    "22",
    "23",
    "24",
    "25",
    "26",
    "27",
    "28",
    "29",
    "30",
    "31",
    "32",
    "33",
    "34",
    "35",
    "36",
    "37",
    "38",
    "39",
    "40",
    "41",
    "42",
    "44",
    "45",
    "46",
    "47",
    "48",
    "49",
    "50",
    "51",
    "53",
    "54",
    "55",
    "56",
    "72",
}

FIELD_CANDIDATES = {
    "state": ("STATEFP", "STATEFP10", "STATE"),
    "county": ("COUNTYFP", "COUNTYFP10", "COUNTY"),
    "tract": ("TRACTCE", "TRACTCE10", "TRACT"),
    "block_group": ("BLKGRPCE", "BLKGRPCE10", "BLKGRP"),
    "name": ("NAME", "NAME10"),
    "namelsad": ("NAMELSAD", "NAMELSAD10"),
}


class HrefParser(html.parser.HTMLParser):
    def __init__(self) -> None:
        super().__init__()
        self.hrefs: list[str] = []

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        if tag != "a":
            return
        for key, value in attrs:
            if key == "href" and value:
                self.hrefs.append(value)


def fetch_text(url: str, retries: int = 5, timeout: int = 120) -> str:
    last_error: Exception | None = None
    for attempt in range(retries):
        try:
            request = urllib.request.Request(url, headers=REQUEST_HEADERS)
            with urllib.request.urlopen(request, timeout=timeout) as response:
                charset = response.headers.get_content_charset() or "utf-8"
                return response.read().decode(charset, errors="replace")
        except (urllib.error.URLError, TimeoutError, OSError) as err:
            last_error = err
            if attempt + 1 == retries:
                break
            time.sleep(2 * (attempt + 1))
    assert last_error is not None
    raise last_error


def is_valid_zip(path: Path) -> bool:
    if not path.exists() or path.stat().st_size == 0:
        return False
    try:
        with zipfile.ZipFile(path) as archive:
            names = archive.namelist()
            if not names:
                return False
            return any(name.endswith(".shp") for name in names)
    except (zipfile.BadZipFile, OSError):
        return False


def read_small_text(path: Path, limit: int = 4096) -> str:
    try:
        return path.read_text(encoding="utf-8", errors="replace")[:limit]
    except OSError:
        return ""


def is_waf_rejection(path: Path) -> bool:
    text = read_small_text(path)
    return "Request Rejected" in text or "support ID is:" in text


def download_file(urls: list[str], output: Path, retries: int = 5, timeout: int = 120) -> None:
    output.parent.mkdir(parents=True, exist_ok=True)
    tmp = output.with_suffix(output.suffix + ".tmp")
    err_path = output.with_suffix(output.suffix + ".err")

    if is_valid_zip(output):
        return
    output.unlink(missing_ok=True)
    err_path.unlink(missing_ok=True)

    last_error: Exception | None = None
    for url_index, url in enumerate(urls, start=1):
        if url_index > 1:
            log_progress(f" fallback source for {output.name}: {Path(url).name}")
        for attempt in range(retries):
            try:
                time.sleep(REQUEST_PAUSE_SECONDS)
                if shutil.which("curl"):
                    subprocess.run(
                        [
                            "curl",
                            "--silent",
                            "--show-error",
                            "--location",
                            "--fail-with-body",
                            "--retry",
                            str(retries),
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
                if not is_valid_zip(tmp):
                    tmp.replace(err_path)
                    raise zipfile.BadZipFile(f"downloaded file is not a valid zip archive: {url}")
                tmp.replace(output)
                err_path.unlink(missing_ok=True)
                return
            except (
                urllib.error.URLError,
                TimeoutError,
                OSError,
                subprocess.CalledProcessError,
                zipfile.BadZipFile,
            ) as exc:
                last_error = exc
                tmp.unlink(missing_ok=True)
                if is_waf_rejection(err_path):
                    backoff = 15 * (attempt + 1)
                    log_progress(f" WAF rejection for {Path(url).name}; sleeping {backoff}s before retry")
                    time.sleep(backoff)
                if attempt + 1 == retries:
                    break
                time.sleep(2 * (attempt + 1))

    assert last_error is not None
    raise last_error


def parse_listing(url: str) -> list[str]:
    parser = HrefParser()
    parser.feed(fetch_text(url))
    names = {Path(href).name for href in parser.hrefs if href}
    return sorted(name for name in names if name.endswith(".zip"))


def directory_candidates(year: int, level: str) -> list[str]:
    root = f"https://www2.census.gov/geo/tiger/TIGER{year}"
    if year == 2010:
        if level == "state":
            return [f"{root}/STATE/2010", f"{root}/STATE"]
        if level == "county":
            return [f"{root}/COUNTY/2010", f"{root}/COUNTY"]
        if level == "tract":
            return [f"{root}/TRACT/2010", f"{root}/TRACT"]
        if level == "block_group":
            return [f"{root}/BG/2010", f"{root}/BG"]

    folder = {
        "state": "STATE",
        "county": "COUNTY",
        "tract": "TRACT",
        "block_group": "BG",
    }[level]
    return [f"{root}/{folder}"]


def filename_pattern(year: int, level: str) -> re.Pattern[str]:
    if level == "state":
        suffix = "state10" if year == 2010 else "state"
        return re.compile(rf"tl_{year}_us_{suffix}\.zip$")
    if level == "county":
        suffix = "county10" if year == 2010 else "county"
        return re.compile(rf"tl_{year}_us_{suffix}\.zip$")
    if level == "tract":
        if year == 2010:
            return re.compile(rf"tl_{year}_[0-9]{{2}}(?:[0-9]{{3}})?_tract10\.zip$")
        return re.compile(rf"tl_{year}_[0-9]{{2}}_tract\.zip$")
    if year == 2010:
        return re.compile(rf"tl_{year}_[0-9]{{2}}(?:[0-9]{{3}})?_bg10\.zip$")
    return re.compile(rf"tl_{year}_[0-9]{{2}}_bg\.zip$")


def tiger_zip_urls(year: int, level: str) -> list[str]:
    root = f"https://www2.census.gov/geo/tiger/TIGER{year}"

    if level == "state":
        suffix = "state10" if year == 2010 else "state"
        directory = "STATE/2010" if year == 2010 else "STATE"
        return [f"{root}/{directory}/tl_{year}_us_{suffix}.zip"]

    if level == "county":
        suffix = "county10" if year == 2010 else "county"
        directory = "COUNTY/2010" if year == 2010 else "COUNTY"
        return [f"{root}/{directory}/tl_{year}_us_{suffix}.zip"]

    if year >= 2011 and level == "tract":
        return [f"{root}/TRACT/tl_{year}_{state}_tract.zip" for state in sorted(SUPPORTED_STATE_FIPS)]

    if year >= 2011 and level == "block_group":
        return [f"{root}/BG/tl_{year}_{state}_bg.zip" for state in sorted(SUPPORTED_STATE_FIPS)]

    pattern = filename_pattern(year, level)

    for directory in directory_candidates(year, level):
        names = [name for name in parse_listing(directory) if pattern.fullmatch(name)]
        if names:
            return [f"{directory}/{name}" for name in names]

    raise RuntimeError(f"could not find TIGER zip files for {level} {year}")


def zip_sources(year: int, level: str) -> list[tuple[str, list[str]]]:
    urls = tiger_zip_urls(year, level)
    if year == 2010 and level in {"tract", "block_group"}:
        sources = []
        for url in urls:
            parts = Path(url).name.split("_")
            state = parts[2][:2]
            genz_code = "140_00" if level == "tract" else "150_00"
            fallback = f"https://www2.census.gov/geo/tiger/GENZ2010/gz_2010_{state}_{genz_code}_500k.zip"
            sources.append((Path(url).name, [url, fallback]))
        return sources

    if year >= 2011 and level in {"tract", "block_group"}:
        sources = []
        for url in urls:
            state = Path(url).name.split("_")[2]
            cb_kind = "tract" if level == "tract" else "bg"
            fallback = f"https://www2.census.gov/geo/tiger/GENZ{year}/shp/cb_{year}_{state}_{cb_kind}_500k.zip"
            sources.append((Path(url).name, [url, fallback]))
        return sources
    return [(Path(url).name, [url]) for url in urls]


def choose(row: dict[str, str], *candidates: str) -> str:
    for candidate in candidates:
        value = row.get(candidate)
        if value is not None and value != "":
            return value.strip()
    raise KeyError(f"missing all candidate fields: {', '.join(candidates)}")


def geometry_label(row: dict[str, str], level: str) -> str:
    try:
        return choose(row, *FIELD_CANDIDATES["namelsad"])
    except KeyError:
        pass

    name = choose(row, *FIELD_CANDIDATES["name"])
    lsad = row.get("LSAD", "").strip().upper()

    if level == "tract":
        if lsad in {"CT", "TRACT"}:
            return f"Census Tract {name}"
        return f"Census Tract {name}"

    if level == "block_group":
        if lsad in {"BG", "BLOCK GROUP"}:
            return f"Block Group {name}"
        return f"Block Group {name}"

    return name


def extract_rows(zip_path: Path) -> list[dict[str, str]]:
    with tempfile.TemporaryDirectory() as tmpdir:
        with zipfile.ZipFile(zip_path) as archive:
            archive.extractall(tmpdir)

        shp_files = sorted(Path(tmpdir).glob("*.shp"))
        if not shp_files:
            raise FileNotFoundError(f"zip archive does not contain a shapefile: {zip_path}")

        output_dir = Path(tmpdir) / "csv"
        subprocess.run(
            ["ogr2ogr", "-f", "CSV", str(output_dir), str(shp_files[0])],
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
        )
        csv_files = sorted(output_dir.glob("*.csv"))
        if not csv_files:
            raise FileNotFoundError(f"ogr2ogr did not produce a CSV for {zip_path}")
        for encoding in ("utf-8", "latin-1"):
            try:
                with csv_files[0].open(newline="", encoding=encoding) as src:
                    return list(csv.DictReader(src))
            except UnicodeDecodeError:
                continue
        raise UnicodeDecodeError("csv", b"", 0, 1, f"unable to decode {csv_files[0]}")


def update_unique(target: dict, key, value: str) -> None:
    existing = target.get(key)
    if existing is not None and existing != value:
        raise ValueError(f"conflicting values for {key}: {existing!r} vs {value!r}")
    target[key] = value


def read_lookup(path: Path, keys: list[str], value: str) -> dict[tuple[str, ...], str]:
    with path.open(newline="", encoding="utf-8") as src:
        reader = csv.DictReader(src)
        return {
            tuple(row[key] for key in keys): row[value]
            for row in reader
        }


def log_progress(message: str) -> None:
    print(message, file=sys.stderr, flush=True)


def iter_zip_rows(year: int, level: str, cache_dir: Path):
    sources = zip_sources(year, level)
    total = len(sources)
    for index, (zip_name, urls) in enumerate(sources, start=1):
        zip_path = cache_dir / str(year) / zip_name
        source = "cached" if is_valid_zip(zip_path) else "download"
        log_progress(f" [{year} {level} {index}/{total}] {source} {zip_name}")
        download_file(urls, zip_path)
        log_progress(f" [{year} {level} {index}/{total}] extract {zip_name}")
        yield zip_name, extract_rows(zip_path)


def write_csv(path: Path, fieldnames: list[str], rows: list[dict[str, str]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="", encoding="utf-8") as dst:
        writer = csv.DictWriter(
            dst,
            fieldnames=fieldnames,
            quoting=csv.QUOTE_ALL,
            lineterminator="\n",
        )
        writer.writeheader()
        writer.writerows(rows)


def state_rows(year: int, cache_dir: Path) -> list[dict[str, str]]:
    records: dict[str, str] = {}

    for _, rows in iter_zip_rows(year, "state", cache_dir):
        for row in rows:
            state = choose(row, *FIELD_CANDIDATES["state"])
            if state not in SUPPORTED_STATE_FIPS:
                continue
            update_unique(records, state, choose(row, *FIELD_CANDIDATES["name"]))

    return [
        {"state": state, "name": records[state]}
        for state in sorted(records)
    ]


def county_rows(year: int, cache_dir: Path, states_path: Path) -> list[dict[str, str]]:
    state_names = read_lookup(states_path, ["state"], "name")
    records: dict[tuple[str, str], str] = {}

    for _, rows in iter_zip_rows(year, "county", cache_dir):
        for row in rows:
            state = choose(row, *FIELD_CANDIDATES["state"])
            if state not in SUPPORTED_STATE_FIPS:
                continue
            county = choose(row, *FIELD_CANDIDATES["county"])
            county_name = geometry_label(row, "county")
            state_name = state_names[(state,)]
            update_unique(records, (state, county), f"{county_name}, {state_name}")

    return [
        {"state": state, "county": county, "name": records[(state, county)]}
        for state, county in sorted(records)
    ]


def tract_rows(year: int, cache_dir: Path, counties_path: Path) -> list[dict[str, str]]:
    county_names = read_lookup(counties_path, ["state", "county"], "name")
    records: dict[tuple[str, str, str], str] = {}

    for zip_name, rows in iter_zip_rows(year, "tract", cache_dir):
        zip_records = 0
        for row in rows:
            state = choose(row, *FIELD_CANDIDATES["state"])
            if state not in SUPPORTED_STATE_FIPS:
                continue
            county = choose(row, *FIELD_CANDIDATES["county"])
            tract = choose(row, *FIELD_CANDIDATES["tract"])
            tract_name = geometry_label(row, "tract")
            county_name = county_names[(state, county)]
            update_unique(records, (state, county, tract), f"{tract_name}, {county_name}")
            zip_records += 1
        log_progress(f" [{year} tract] loaded {zip_records} rows from {zip_name}")

    return [
        {
            "state": state,
            "county": county,
            "tract": tract,
            "name": records[(state, county, tract)],
        }
        for state, county, tract in sorted(records)
    ]


def block_group_rows(year: int, cache_dir: Path, tracts_path: Path) -> list[dict[str, str]]:
    tract_names = read_lookup(tracts_path, ["state", "county", "tract"], "name")
    records: dict[tuple[str, str, str, str], str] = {}

    for zip_name, rows in iter_zip_rows(year, "block_group", cache_dir):
        zip_records = 0
        for row in rows:
            state = choose(row, *FIELD_CANDIDATES["state"])
            if state not in SUPPORTED_STATE_FIPS:
                continue
            county = choose(row, *FIELD_CANDIDATES["county"])
            tract = choose(row, *FIELD_CANDIDATES["tract"])
            block_group = choose(row, *FIELD_CANDIDATES["block_group"])
            bg_name = geometry_label(row, "block_group")
            tract_name = tract_names[(state, county, tract)]
            update_unique(records, (state, county, tract, block_group), f"{bg_name}, {tract_name}")
            zip_records += 1
        log_progress(f" [{year} block_group] loaded {zip_records} rows from {zip_name}")

    return [
        {
            "state": state,
            "county": county,
            "tract": tract,
            "block_group": block_group,
            "name": records[(state, county, tract, block_group)],
        }
        for state, county, tract, block_group in sorted(records)
    ]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--year", required=True, type=int)
    parser.add_argument(
        "--level",
        required=True,
        choices=("state", "county", "tract", "block_group"),
    )
    parser.add_argument("--cache-dir", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--states", type=Path)
    parser.add_argument("--counties", type=Path)
    parser.add_argument("--tracts", type=Path)
    return parser.parse_args()


def main() -> int:
    args = parse_args()

    if args.level == "state":
        rows = state_rows(args.year, args.cache_dir)
        write_csv(args.output, ["state", "name"], rows)
        return 0

    if args.level == "county":
        if args.states is None:
            raise SystemExit("--states is required for county builds")
        rows = county_rows(args.year, args.cache_dir, args.states)
        write_csv(args.output, ["state", "county", "name"], rows)
        return 0

    if args.level == "tract":
        if args.counties is None:
            raise SystemExit("--counties is required for tract builds")
        rows = tract_rows(args.year, args.cache_dir, args.counties)
        write_csv(args.output, ["state", "county", "tract", "name"], rows)
        return 0

    if args.tracts is None:
        raise SystemExit("--tracts is required for block_group builds")
    rows = block_group_rows(args.year, args.cache_dir, args.tracts)
    write_csv(args.output, ["state", "county", "tract", "block_group", "name"], rows)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
