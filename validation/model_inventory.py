# Check which components of AMRs are present, report!
#
# Some parts of an AMR are optional but required in specific use-contexts.
# This is valuable as an AMR can be used in multiple contexts, some of which
# may fill in additional information.  This script/module loads a schema
# and inventories what is present.  (CLI can process more than one schema).

import json
from itertools import chain
from pathlib import Path
from typing import Union

import sympy


def fetch_path(path, doc):
    """Fetches a literal path from a json document.  (A named-key-descent)."""
    for step in path:
        doc = doc[step]
    return doc


def fetch_parameters(amr):
    # Based on schema, the parameters are found in different places...
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

    return summary, result


def rate_law_parse(amr: dict):
    "Check that each rate-law refers to vars/params defined in the amr"
    try:
        rates = fetch_path(["semantics", "ode", "rates"], amr)
    except KeyError as e:
        return "missing rate semantics section", str(e)

    try:
        params = fetch_parameters(amr)
    except KeyError as e:
        return "missing param semantics section", str(e)

    try:
        states = fetch_path(["model", "states"], amr)
    except KeyError as e:
        return "missing state list", str(e)

    vars = {e["id"]: sympy.Symbol(e["id"]) for e in chain(states, params)}
    for rate in rates:
        try:
            in_expr = rate["expression"]
            out_expr = sympy.parse_expr(in_expr, local_dict=vars)
        except Exception:
            return "Rate law expression invalid", f"Error parsing: {in_expr}"

    defs = {str(s): s in vars.keys() for s in out_expr.free_symbols}
    return all(defs.values()), defs


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


def _load_data(source):
    """Converts a data source to a JSON.

    return pair of loaded-json, description-of-origin
    """
    if isinstance(source, str):
        try:
            parsed = urlparse(source)
            if parsed.scheme != "":
                return requests.get(source).json(), source
        except BaseException:
            pass

        source = Path(source)

    if isinstance(source, Path):
        with open(source) as f:
            return json.load(f), str(source)
    else:
        return source, "<json>"


def check_amr(source: Union[dict, Path, str], summary=False):
    """Do a battery of testa against an AMR.

    Args:
        source (Union[dict, Path, str]): AMR data as JSON-like object
                or file-path (string or Path)
        summary (bool, optional): Produce details, or just a true/false
                summary for each test? (Default false)

    Returns:
        JSON description of inventory resutls
    """
    data, source_id = _load_data(source)

    part = 0 if summary else 1

    try:
        return {
            "source": source_id,
            "parameter distribution exists": param_at_least_one_distribution(data)[
                part
            ],
            "parameter dist/value set": param_distribution_or_value(data)[part],
            "rate laws present": rate_laws(data)[part],
            "rate law vars defined": rate_law_parse(data)[part],
            "initial values present": initial_values(data)[part],
            "observables found": observables(data)[part],
        }
    except Exception as e:
        if source_id != "json":
            source_id = str(source)
        return {"source": source_id, "message": str(e)}


if __name__ == "__main__":
    import argparse
    from urllib.parse import urlparse

    import requests

    parser = argparse.ArgumentParser()
    parser.add_argument(
        "sources",
        nargs="+",
        type=str,
        help=(
            "Files to parse OR urls to download and parse\n"
            "(URLs must include the protocol or they will be treated as files)"
        ),
    )
    parser.add_argument(
        "--format",
        choices=["md", "json", "html", "json-detail"],
        default="md",
        help="Output format.  (choose 'md' for human-readable in console).",
    )
    parser.add_argument(
        "--name-length",
        default=30,
        type=int,
        help="Truncate to this many trailing characters",
    )
    args = parser.parse_args()
    summary = args.format != "json-detail"

    results = [check_amr(source, summary) for source in args.sources]
    if args.format in ["html", "md"]:
        try:
            import pandas as pd
        except ImportError:
            print(f"To use {args.format}, pandas must be installed.")
            raise

        errors = [e for e in results if "message" in e]
        cleaned = [e for e in results if "message" not in e]

        if len(cleaned) > 0:
            df = pd.DataFrame(cleaned)
            df["source"] = df["source"].str.slice_replace(
                start=0, stop=-args.name_length, repl="..."
            )
            df = df.set_index("source")

            if args.format == "md":
                print(df.to_markdown())
            elif args.format == "html":
                print(df.to_html())

        for error in errors:
            print(f"Error loading {error['source']}: {error['message']}")

    else:
        print(json.dumps(results, indent=2))
