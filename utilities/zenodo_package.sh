#!/usr/bin/env bash

set -euo pipefail
shopt -s nullglob

usage() {
  cat <<'EOF'
Usage: utilities/zenodo_package.sh [--label LABEL] [--output-dir DIR] [--dry-run]

Create a Zenodo-friendly release bundle from the current repository.

Artifacts:
  - fairadi-data-<label>-source.tar.gz
  - fairadi-data-<label>-adi-release.tar.gz
  - fairadi-data-<label>-cdi-release.tar.gz
  - fairadi-data-<label>-derived-intermediates.tar.gz
  - fairadi-data-<label>-docs-metadata.tar.gz
  - fairadi-data-<label>-README.txt
  - fairadi-data-<label>-SHA256SUMS.txt
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

ARCHIVE_PREFIX="fairadi-data-${LABEL}"

timestamp_utc() {
  TZ=UTC date +"%Y-%m-%dT%H:%M:%SZ"
}

assert_paths_exist() {
  local path
  for path in "$@"; do
    [[ -e "${ROOT}/${path}" ]] || fail "missing required release path: ${path}"
  done
}

collect_paths() {
  local pattern
  for pattern in "$@"; do
    (
      cd "${ROOT}"
      compgen -G "${pattern}" || true
    )
  done | awk '!seen[$0]++'
}

archive_from_paths() {
  local archive="$1"
  shift
  local paths=("$@")
  [[ ${#paths[@]} -gt 0 ]] || fail "no input paths provided for ${archive}"
  assert_paths_exist "${paths[@]}"
  (
    cd "${ROOT}"
    tar -czf "${archive}" "${paths[@]}"
  )
}

source_patterns=(
  "CHANGELOG.md"
  "README.md"
  "CITATION.cff"
  "metadata.json"
  "dcat-us.json"
  "ro-crate-metadata.json"
  "provenance.provn"
  "PROVENANCE.md"
  "LICENSE"
  "LICENSE-data"
  "Makefile"
  "Makevars"
  "FIPS/Makefile"
  "FIPS/README.md"
  "ACS5/Makefile"
  "ACS5/block_group/Makefile"
  "ACS5/county/Makefile"
  "ACS5/state/Makefile"
  "ACS5/tract/Makefile"
  "Decennial/Makefile"
  "Decennial/block_group/Makefile"
  "Decennial/county/Makefile"
  "Decennial/state/Makefile"
  "Decennial/tract/Makefile"
  "ADI/Makefile"
  "ADI/README.md"
  "ADI/README.Rmd"
  "ADI/fairadi_data_dictionary.tsv"
  "ADI/fairadi_codelists.tsv"
  "ADI/fairadi_schema.json"
  "ADI/*.R"
  "CDI/Makefile"
  "CDI/README.md"
  "CDI/README.Rmd"
  "CDI/2025-08-28-team-cdi-calculation-specifications.pdf"
  "CDI/faircdi_data_dictionary.tsv"
  "CDI/faircdi_schema.json"
  "CDI/*.R"
  "utilities/README.md"
  "utilities/*.R"
  "utilities/*.py"
  "utilities/*.sh"
)

adi_release_patterns=(
  "ADI/fairadi.csv.gz"
  "ADI/fairadi_data_dictionary.tsv"
  "ADI/fairadi_codelists.tsv"
  "ADI/fairadi_schema.json"
)

cdi_release_patterns=(
  "CDI/faircdi.csv.gz"
  "CDI/faircdi_data_dictionary.tsv"
  "CDI/faircdi_schema.json"
)

derived_intermediate_patterns=(
  "ADI/topic*.csv.gz"
  "CDI/component*.csv.gz"
)

docs_metadata_patterns=(
  "README.md"
  "ADI/README.md"
  "CDI/README.md"
  "ADI/fairadi_codelists.tsv"
  "CITATION.cff"
  "metadata.json"
  "dcat-us.json"
  "ro-crate-metadata.json"
  "provenance.provn"
  "PROVENANCE.md"
  "LICENSE"
  "LICENSE-data"
  "MANIFEST.tsv"
)

source_paths=($(collect_paths "${source_patterns[@]}"))
adi_release_paths=($(collect_paths "${adi_release_patterns[@]}"))
cdi_release_paths=($(collect_paths "${cdi_release_patterns[@]}"))
derived_intermediate_paths=($(collect_paths "${derived_intermediate_patterns[@]}"))
docs_metadata_paths=($(collect_paths "${docs_metadata_patterns[@]}"))

SOURCE_ARCHIVE="${OUTPUT_DIR}/${ARCHIVE_PREFIX}-source.tar.gz"
ADI_ARCHIVE="${OUTPUT_DIR}/${ARCHIVE_PREFIX}-adi-release.tar.gz"
CDI_ARCHIVE="${OUTPUT_DIR}/${ARCHIVE_PREFIX}-cdi-release.tar.gz"
DERIVED_ARCHIVE="${OUTPUT_DIR}/${ARCHIVE_PREFIX}-derived-intermediates.tar.gz"
DOCS_ARCHIVE="${OUTPUT_DIR}/${ARCHIVE_PREFIX}-docs-metadata.tar.gz"
README_FILE="${OUTPUT_DIR}/${ARCHIVE_PREFIX}-README.txt"
SHA_FILE="${OUTPUT_DIR}/${ARCHIVE_PREFIX}-SHA256SUMS.txt"

if [[ "${DRY_RUN}" -eq 1 ]]; then
  echo "Zenodo package plan"
  echo "label: ${LABEL}"
  echo "output_dir: ${OUTPUT_DIR}"
  echo "source_archive: ${SOURCE_ARCHIVE##*/}"
  echo "adi_release_archive: ${ADI_ARCHIVE##*/}"
  echo "cdi_release_archive: ${CDI_ARCHIVE##*/}"
  echo "derived_intermediates_archive: ${DERIVED_ARCHIVE##*/}"
  echo "docs_metadata_archive: ${DOCS_ARCHIVE##*/}"
  echo "readme: ${README_FILE##*/}"
  echo "checksums: ${SHA_FILE##*/}"
  exit 0
fi

mkdir -p "${OUTPUT_DIR}"

archive_from_paths "${SOURCE_ARCHIVE}" "${source_paths[@]}"
archive_from_paths "${ADI_ARCHIVE}" "${adi_release_paths[@]}"
archive_from_paths "${CDI_ARCHIVE}" "${cdi_release_paths[@]}"
archive_from_paths "${DERIVED_ARCHIVE}" "${derived_intermediate_paths[@]}"
archive_from_paths "${DOCS_ARCHIVE}" "${docs_metadata_paths[@]}"

cat > "${README_FILE}" <<EOF
fairadi-data Zenodo package
label: ${LABEL}
created_utc: $(timestamp_utc)

Files in this release bundle:
- ${ARCHIVE_PREFIX}-source.tar.gz: curated reproducibility subset with build scripts, Makefiles, metadata, and supporting documentation needed to rebuild the tracked release from public source data.
- ${ARCHIVE_PREFIX}-adi-release.tar.gz: canonical ADI release dataset plus its data dictionary and row schema.
- ${ARCHIVE_PREFIX}-cdi-release.tar.gz: canonical CDI release dataset plus its data dictionary and row schema.
- ${ARCHIVE_PREFIX}-derived-intermediates.tar.gz: published ADI topic files and CDI component files used as derived intermediates.
- ${ARCHIVE_PREFIX}-docs-metadata.tar.gz: citation, provenance, licensing, manifest, and top-level release documentation.
- ${ARCHIVE_PREFIX}-SHA256SUMS.txt: checksums for all release files in this folder.

Recommended use:
1. Download ${ARCHIVE_PREFIX}-adi-release.tar.gz and/or ${ARCHIVE_PREFIX}-cdi-release.tar.gz if you only need the released datasets.
2. Download ${ARCHIVE_PREFIX}-docs-metadata.tar.gz for citation, provenance, licensing, and release documentation.
3. Download ${ARCHIVE_PREFIX}-source.tar.gz if you want the curated reproducibility subset for rebuilding from public inputs.
4. Download ${ARCHIVE_PREFIX}-derived-intermediates.tar.gz if you want the published topic/component intermediates.
5. Verify all downloaded files with:
   shasum -a 256 -c ${ARCHIVE_PREFIX}-SHA256SUMS.txt

Notes:
- These archives are designed for Zenodo publication and do not mirror the GitHub file layout one-for-one.
- Code and build scripts are licensed under BSD-3-Clause in LICENSE.
- Released data artifacts and documentation are licensed under CC BY 4.0 in LICENSE-data.
- Reserved Zenodo DOI for the current release: 10.5281/zenodo.19222629
EOF

(
  cd "${OUTPUT_DIR}"
  rm -f "${SHA_FILE}"
  shasum -a 256 \
    "${SOURCE_ARCHIVE##*/}" \
    "${ADI_ARCHIVE##*/}" \
    "${CDI_ARCHIVE##*/}" \
    "${DERIVED_ARCHIVE##*/}" \
    "${DOCS_ARCHIVE##*/}" \
    "${README_FILE##*/}" \
    > "${SHA_FILE##*/}"
)

echo "Created Zenodo package in ${OUTPUT_DIR}"
ls -lh \
  "${SOURCE_ARCHIVE}" \
  "${ADI_ARCHIVE}" \
  "${CDI_ARCHIVE}" \
  "${DERIVED_ARCHIVE}" \
  "${DOCS_ARCHIVE}" \
  "${README_FILE}" \
  "${SHA_FILE}"
