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
        try:
            doc = doc[step]
        except KeyError:
            return None
    return doc


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


def size_largest(issues: list[str, any]) -> Union[None, int]:
    """How many non-empty dict/list/sets in the dict values?
    (None if the dict is empty.)
    """
    if not issues or len(issues) == 0:
        return None
    largest = sorted(issues.values(), key=len, reverse=True)[0]
    return len(largest)


def distributions(amr: dict, summary=False):
    """
    Checks if there each parameter has a distribution or a value
    associated with it.
    """

    paths = [["semantics", "ode", "parameters"], ["semantics", "pde", "parameters"]]

    def _test(entry):
        return "value" in entry or "distriubution" in entry

    issues = {}
    for path in paths:
        target = fetch_path(path, amr)
        if target:
            partial = {"/".join(path + [e["id"]]): _test(e) for e in target}
            issues = {**issues, **partial}

    if summary:
        return count_falses(issues)
    else:
        return issues


def rate_laws(amr: dict, summary: bool = False):
    """Check that each transition has a rate-law semantic"""
    paths = [["semantics", "ode", "rates"], ["semantics", "pde", "rates"]]

    transitions = {e["id"] for e in fetch_path(["model", "transitions"], amr)}

    issues = {}
    for path in paths:
        target = fetch_path(path, amr)
        if target:
            targets = [e["target"] for e in target]
            missing = transitions - set(targets)
            issues["/".join(path)] = missing

    if summary:
        return size_largest(issues)
    else:
        return issues


def initial_values(amr: dict, summary: bool = False):
    paths = [["semantics", "ode", "rates"], ["semantics", "pde", "rates"]]
    states = {e["id"] for e in fetch_path(["model", "states"], amr)}

    issues = {}
    for path in paths:
        target = fetch_path(path, amr)
        if target:
            targets = [e["target"] for e in target]
            missing = states - set(targets)
            issues["/".join(path)] = missing

    if summary:
        return size_largest(issues)
    else:
        return issues


def observables(amr: dict, summary: bool = False):
    """How many observables are there?"""
    paths = [["semantics", "ode", "observables"], ["semantics", "pde", "observables"]]

    found = {}
    for path in paths:
        target = fetch_path(path, amr)
        p = "/".join(path)
        found[p] = [t["id"] for t in target] if target else None

    if summary:
        return count_not_empty(found)
    else:
        return found


def check_schema(source: Union[dict, Path, str], summary=False):
    if isinstance(source, str):
        source = Path(source)

    if isinstance(source, Path):
        source_id = source.name
        with open(source) as f:
            data = json.load(f)
    else:
        source_id = "<json>"
        data = source

    try:
        return {
            "source": source_id,
            "distributions": distributions(data, summary),
            "rate laws": rate_laws(data, summary),
            "initial values": initial_values(data, summary),
            "observables": observables(data, summary),
        }
    except Exception:
        if source_id != "json":
            source_id = str(source)
        print(f"Error processing {source_id}")
        return {"source": source_id}


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

        df = pd.DataFrame(results).set_index("source")
        print("Summary of failures")
        print(df.to_markdown())
    else:
        print(results)
