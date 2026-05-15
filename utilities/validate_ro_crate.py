#!/usr/bin/env python3

import json
import subprocess
import sys
from pathlib import Path


RO_CRATE_PATH = Path("ro-crate-metadata.json")

REQUIRED_ENTITY_IDS = {
    "ro-crate-metadata.json",
    "./",
    "#release-doi",
    "README.md",
    "metadata.json",
    "dcat-us.json",
    "CITATION.cff",
    "PROVENANCE.md",
    "provenance.provn",
    "MANIFEST.tsv",
    "ADI/fairadi.csv.gz",
    "ADI/fairadi_data_dictionary.tsv",
    "ADI/fairadi_schema.json",
    "CDI/faircdi.csv.gz",
    "CDI/faircdi_data_dictionary.tsv",
    "CDI/faircdi_schema.json",
    "#build-adi-action",
    "#build-cdi-action",
    "#build-manifest-action",
    "#package-release-action",
    "#register-doi-action",
}

REQUIRED_ACTION_IDS = {
    "#build-adi-action",
    "#build-cdi-action",
    "#build-manifest-action",
    "#package-release-action",
    "#register-doi-action",
}


def git_root(start: Path) -> Path:
    proc = subprocess.run(
        ["git", "rev-parse", "--show-toplevel"],
        cwd=start,
        check=True,
        capture_output=True,
        text=True,
    )
    return Path(proc.stdout.strip())


def as_list(value):
    if value is None:
        return []
    if isinstance(value, list):
        return value
    return [value]


def local_repo_path(entity_id: str) -> Path | None:
    if entity_id in {"./", "ro-crate-metadata.json"}:
        return Path("ro-crate-metadata.json") if entity_id == "ro-crate-metadata.json" else None
    if entity_id.startswith("#"):
        return None
    if entity_id.startswith("http://") or entity_id.startswith("https://"):
        return None
    return Path(entity_id)


def validate(root: Path) -> list[str]:
    errors: list[str] = []
    crate_path = root / RO_CRATE_PATH
    try:
        crate = json.loads(crate_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        return [f"invalid JSON in {RO_CRATE_PATH}: {exc}"]

    context = crate.get("@context")
    if context != "https://w3id.org/ro/crate/1.2/context":
        errors.append("ro-crate-metadata.json has unexpected @context")

    graph = crate.get("@graph")
    if not isinstance(graph, list):
        return ["ro-crate-metadata.json is missing an @graph array"]

    entities = {}
    for node in graph:
        if not isinstance(node, dict):
            errors.append("@graph contains a non-object entry")
            continue
        node_id = node.get("@id")
        if not isinstance(node_id, str):
            errors.append("@graph contains an entity without a string @id")
            continue
        entities[node_id] = node

    missing_ids = REQUIRED_ENTITY_IDS - set(entities)
    for entity_id in sorted(missing_ids):
        errors.append(f"missing required RO-Crate entity: {entity_id}")

    metadata_entity = entities.get("ro-crate-metadata.json")
    if metadata_entity is not None:
        if metadata_entity.get("@type") != "CreativeWork":
            errors.append("ro-crate-metadata.json entity should have @type CreativeWork")
        about = metadata_entity.get("about", {})
        if about.get("@id") != "./":
            errors.append("ro-crate-metadata.json entity should reference ./ via about")
        conforms_to = metadata_entity.get("conformsTo", {})
        if conforms_to.get("@id") != "https://w3id.org/ro/crate/1.2":
            errors.append("ro-crate-metadata.json entity should conform to RO-Crate 1.2")

    root_dataset = entities.get("./")
    if root_dataset is not None:
        root_types = set(as_list(root_dataset.get("@type")))
        if "Dataset" not in root_types:
            errors.append("root RO-Crate entity ./ should include @type Dataset")
        has_part_ids = {entry.get("@id") for entry in as_list(root_dataset.get("hasPart")) if isinstance(entry, dict)}
        for entity_id in [
            "README.md",
            "metadata.json",
            "dcat-us.json",
            "CITATION.cff",
            "PROVENANCE.md",
            "provenance.provn",
            "MANIFEST.tsv",
            "ADI/fairadi.csv.gz",
            "CDI/faircdi.csv.gz",
        ]:
            if entity_id not in has_part_ids:
                errors.append(f"root dataset is missing hasPart reference to {entity_id}")

    for action_id in REQUIRED_ACTION_IDS:
        node = entities.get(action_id)
        if node is None:
            continue
        action_types = set(as_list(node.get("@type")))
        if "CreateAction" not in action_types:
            errors.append(f"{action_id} should include @type CreateAction")
        for field in ("name", "agent", "result", "actionStatus"):
            if field not in node:
                errors.append(f"{action_id} is missing required field {field}")

    for entity_id, node in entities.items():
        path = local_repo_path(entity_id)
        if path is not None:
            full_path = root / path
            if entity_id.endswith("/"):
                if not full_path.is_dir():
                    errors.append(f"RO-Crate directory reference does not exist: {entity_id}")
            else:
                if not full_path.is_file():
                    errors.append(f"RO-Crate file reference does not exist: {entity_id}")

        for key in ("license", "identifier", "url", "creator", "mentions", "hasPart", "isBasedOn", "instrument", "object", "result", "agent"):
            for value in as_list(node.get(key)):
                if isinstance(value, dict) and "@id" in value:
                    ref_id = value["@id"]
                    if ref_id.startswith("#") and ref_id not in entities:
                        errors.append(f"{entity_id} references missing local entity {ref_id}")
                    if not ref_id.startswith("#") and not ref_id.startswith("http://") and not ref_id.startswith("https://") and ref_id not in entities:
                        errors.append(f"{entity_id} references missing entity {ref_id}")

    return errors


def main() -> int:
    root = git_root(Path.cwd())
    errors = validate(root)
    if errors:
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
        return 1
    print("Validated ro-crate-metadata.json with repository checks.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
