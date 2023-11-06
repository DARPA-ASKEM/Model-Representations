# Check which components of AMRs are present, report!
#
# Some parts of an AMR are optional but required in specific use-contexts.
# This is valuable as an AMR can be used in multiple contexts, some of which
# may fill in additional information.  This script/module loads a schema
# and inventories what is present.  (CLI can process more than one schema).

from pathlib import Path
from typing import Union
import json


def fetch_path(path, doc):
    """Fetches a literal path from a json document.  (A named-key-descent)."""
    for step in path:
        doc = doc[step]
    return doc


def fetch_parameters(amr):
    if amr["header"].get("schema_name", None) == "regnet":
        return fetch_path(["model", "parameters"], amr)
    else:
        return fetch_path(["semantics", "ode", "parameters"], amr)


def count_falses(issues: list[str, bool]) -> Union[None, int]:
    """How many falses in the dict valeus? (None if the dict is empty.)"""
    if not issues or len(issues) == 0:
        return None
    return len(issues) - sum([*issues.values()])


def count_not_empty(issues: list[str, any]) -> Union[None, int]:
    """How many non-empty dict/list/sets in the dict values?
    (None if the dict is empty.)
    """
    if not issues or len(issues) == 0:
        return None
    return len(issues) - sum([(v is None or len(v) == 0) for v in issues.values()])


def param_distribution_or_value(amr: dict, summary=False):
    """
    Does each parameter have a distribution or a value associated with it?
    """
    try:
        semantics = fetch_parameters(amr)
    except KeyError as e:
        return "missing param semantics", str(e)

    result = {e["id"]: ("value" in e or "distribution" in e) for e in semantics}
    summary = all(result.values())

    return summary, result


def param_at_least_one_distribution(amr: dict):
    "Is there at least one parameter with a distribution"
    try:
        semantics = fetch_parameters(amr)
    except KeyError as e:
        raise e
        return "missing param semantics section", str(e)

    has_dist = {e["id"]: "distribution" in e for e in semantics}
    result = any(has_dist.values())
    return result, result


def rate_laws(amr: dict):
    "Check that each transition has a rate-law semantic that is well-formed"
    try:
        semantics = fetch_path(["semantics", "ode", "rates"], amr)
    except KeyError as e:
        return "missing rate semantics section", str(e)

    transitions = {e["id"] for e in fetch_path(["model", "transitions"], amr)}
    rate_targets = [e["target"] for e in semantics]
    result = {t: t in rate_targets for t in transitions}
    summary = all(result.values())

    # -- For each rate law: Parse teh 'expression' with sympy, check that those variables exist in the AMR as a state or a parameter
    return summary, result


def initial_values(amr: dict):
    """Check that each state has an initial value"""
    try:
        inits = fetch_path(["semantics", "ode", "initials"], amr)
    except KeyError as e:
        return "missing initial value section", str(e)

    try:
        states = {e["id"] for e in fetch_path(["model", "states"], amr)}
    except KeyError as e:
        return "missing state list", str(e)

    init_targets = [e["target"] for e in inits]
    result = {s: s in init_targets for s in states}
    summary = all(result.values())

    return summary, result


def observables(amr: dict):
    """How many observables are there?"""
    try:
        semantics = fetch_path(["semantics", "ode", "observables"], amr)
    except KeyError:
        return 0, "No observables section found"

    result = [t["id"] for t in semantics]
    summary = len(result)

    return summary, result


# -- CHeck the 'schema_name', only use the 'right parser' for each schema (maybe go through mira)
#  - stock-and-flow


def check_schema(source: Union[dict, Path, str], summary=False):
    if isinstance(source, str):
        source = Path(source)

    if isinstance(source, Path):
        source_id = str(source)
        with open(source) as f:
            data = json.load(f)
    else:
        source_id = "<json>"
        data = source

    part = 0 if summary else 1

    try:
        return {
            "source": source_id,
            "parameter distribtuion exists": param_at_least_one_distribution(data)[
                part
            ],
            "parameter dist/value set": param_distribution_or_value(data)[part],
            "rate laws present": rate_laws(data)[part],
            "initial values present": initial_values(data)[part],
            "observables found": observables(data)[part],
        }
    except Exception as e:
        if source_id != "json":
            source_id = str(source)
        return {"source": source_id, "message": str(e)}


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument("files", nargs="+", type=Path, help="Files to parse")
    parser.add_argument(
        "--format",
        choices=["txt", "json"],
        default="txt",
        help="Output format.  'txt' for human-readable (requires pandas), 'json' for machine-parsed.",
    )
    args = parser.parse_args()
    summary = args.format == "txt"

    results = [check_schema(file, summary) for file in args.files]
    if args.format == "txt":
        import pandas as pd

        errors = [e for e in results if "message" in e]
        cleaned = [e for e in results if "message" not in e]

        if len(cleaned) > 0:
            df = pd.DataFrame(cleaned).set_index("source")
            print(df.to_markdown())

        for error in errors:
            print(f"Error loading {error['source']}: {error['message']}")

    else:
        print(json.dumps(results, indent=2))
