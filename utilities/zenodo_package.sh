#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: utilities/zenodo_package.sh [--label LABEL] [--output-dir DIR] [--dry-run]

Create a Zenodo-friendly release bundle from the current repository.

Artifacts:
  - fairadi-<label>-source.tar.gz
  - fairadi-<label>-README.txt
  - fairadi-<label>-SHA256SUMS.txt

The source archive comes from `git archive HEAD`, so it excludes `.git/` and
other untracked build products while preserving the git-tracked annual release
snapshot intended for publication.
EOF
}

fail() {
  echo "Error: $*" >&2
  exit 1
}

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
[[ -n "${ROOT}" ]] || fail "this script must be run from inside the git repository"

LABEL="$(
  python3 - <<'PY' 2>/dev/null || true
import json
from pathlib import Path
path = Path("metadata.json")
if path.exists():
    metadata = json.loads(path.read_text(encoding="utf-8"))
    print(metadata.get("provenance", {}).get("git_ref", f"v{metadata['version']}"))
PY
)"
LABEL="${LABEL:-$(git describe --tags --always --dirty 2>/dev/null || git rev-parse --short HEAD)}"
OUTPUT_DIR="${ROOT}/zenodo-dist"
DRY_RUN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --label)
      [[ $# -ge 2 ]] || fail "--label requires a value"
      LABEL="$2"
      shift 2
      ;;
    --output-dir)
      [[ $# -ge 2 ]] || fail "--output-dir requires a value"
      OUTPUT_DIR="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      fail "unknown argument: $1"
      ;;
  esac
done

ARCHIVE_PREFIX="fairadi-${LABEL}"

timestamp_utc() {
  TZ=UTC date +"%Y-%m-%dT%H:%M:%SZ"
}

if [[ "${DRY_RUN}" -eq 1 ]]; then
  echo "Zenodo package plan"
  echo "label: ${LABEL}"
  echo "output_dir: ${OUTPUT_DIR}"
  echo "source_archive: ${ARCHIVE_PREFIX}-source.tar.gz"
  exit 0
fi

mkdir -p "${OUTPUT_DIR}"

README_FILE="${OUTPUT_DIR}/${ARCHIVE_PREFIX}-README.txt"
SHA_FILE="${OUTPUT_DIR}/${ARCHIVE_PREFIX}-SHA256SUMS.txt"

cat > "${README_FILE}" <<EOF
fairadi Zenodo package
label: ${LABEL}
created_utc: $(timestamp_utc)

Files in this release bundle:
- ${ARCHIVE_PREFIX}-source.tar.gz: git-tracked source snapshot from HEAD.
- ADI/fairadi.csv.gz: canonical released dataset artifact inside the source archive.
- ADI/fairadi_data_dictionary.tsv: column-level schema for ADI release files inside the source archive.
- CDI/faircdi.csv.gz: CDI output dataset inside the source archive.
- CDI/README.md: CDI process documentation inside the source archive.
- CITATION.cff, metadata.json, PROVENANCE.md, and MANIFEST.tsv: release metadata and provenance files inside the source archive.
- ${ARCHIVE_PREFIX}-SHA256SUMS.txt: checksums for all archives in this folder.

Recommended unpacking workflow:
1. Create an empty directory for the release contents.
2. Extract ${ARCHIVE_PREFIX}-source.tar.gz into that directory.
3. Verify checksums before upload or after download with:
   shasum -a 256 -c ${ARCHIVE_PREFIX}-SHA256SUMS.txt

Notes:
- The source archive excludes .git/ and untracked build products.
- This repository now tracks the annual release snapshot intended for data use,
  including ADI and CDI work, so a single source archive is sufficient for the
  Zenodo publication record.
- Ignored scratch files remain outside the archival release by design.
- Code and build scripts are licensed under BSD-3-Clause in LICENSE.
- Released data artifacts and documentation are licensed under CC BY 4.0 in LICENSE-data.
- Reserved Zenodo DOI for the current release: 10.5281/zenodo.19222629
EOF

SOURCE_ARCHIVE="${OUTPUT_DIR}/${ARCHIVE_PREFIX}-source.tar.gz"
git -C "${ROOT}" archive --format=tar.gz --prefix="${ARCHIVE_PREFIX}/" -o "${SOURCE_ARCHIVE}" HEAD

(
  cd "${OUTPUT_DIR}"
  rm -f "${SHA_FILE}"
  shasum -a 256 \
    "${ARCHIVE_PREFIX}-source.tar.gz" \
    "${ARCHIVE_PREFIX}-README.txt" \
    > "${ARCHIVE_PREFIX}-SHA256SUMS.txt"
)

echo "Created Zenodo package in ${OUTPUT_DIR}"
ls -lh "${OUTPUT_DIR}/${ARCHIVE_PREFIX}"*
