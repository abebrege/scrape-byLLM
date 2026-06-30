import argparse
import json
import sys

from comparison import run_comparison
from comparison_parameters import COMPARISONS, DEFAULT_COMPARISON


def main() -> None:
    parser = argparse.ArgumentParser(description="Run scraping comparison benchmarks.")
    group = parser.add_mutually_exclusive_group()
    group.add_argument(
        "--name",
        metavar="NAME",
        help=f"Run a specific comparison. Choices: {', '.join(COMPARISONS)}",
    )
    group.add_argument("--all", action="store_true", help="Run all comparisons")
    args = parser.parse_args()

    if args.all:
        names = list(COMPARISONS.keys())
    elif args.name:
        if args.name not in COMPARISONS:
            print(
                f"Unknown comparison '{args.name}'. Available: {', '.join(COMPARISONS)}",
                file=sys.stderr,
            )
            sys.exit(1)
        names = [args.name]
    else:
        names = [DEFAULT_COMPARISON]

    for name in names:
        params = COMPARISONS[name]
        print(f"\n=== {name} (category {params.category}, {params.failure_type}) ===")
        print(f"URL:   {params.url}")
        print(f"Query: {params.query}")

        result = run_comparison(params)

        with open(params.output_file, "w", encoding="utf-8") as f:
            json.dump(result, f, indent=2, ensure_ascii=False)
        print(f"  -> {params.output_file}")


if __name__ == "__main__":
    main()
