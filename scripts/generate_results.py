"""Generate RESULTS.md from a directory of comparison_*.json output files."""
import argparse
import glob
import json
import os
import sys

RUN_KEYS = [
    ("direct_anthropic", "Direct Anthropic API"),
    ("byllm",            "byLLM"),
    ("direct_byllm",     "Direct byLLM"),
    ("direct_pipeline",  "Direct Pipeline"),
]


def generate(data_dir: str, output_path: str) -> None:
    pattern = os.path.join(data_dir, "comparison_*.json")
    files = sorted(glob.glob(pattern))
    if not files:
        print(f"No comparison_*.json files found in {data_dir!r}", file=sys.stderr)
        sys.exit(1)

    sections = []
    for path in files:
        with open(path, encoding="utf-8") as f:
            d = json.load(f)
        name = os.path.basename(path).replace("comparison_", "").replace(".json", "")
        sections.append((name, d))

    sections.sort(key=lambda x: (x[1].get("category", 99), x[0]))

    lines = ["# Comparison Results\n"]

    for name, d in sections:
        cat = d.get("category", "?")
        failure = d.get("failure_type", "?")
        query = d.get("query", "")
        description = d.get("description", "")

        title = name.replace("_", " ").title()
        lines.append(f"## {title}")
        lines.append(f"**Category {cat} — {failure}**  ")
        lines.append(f"**Query:** {query}  ")
        lines.append(f"**Description:** {description}\n")

        for key, label in RUN_KEYS:
            result = d.get(key, {})
            synthesis = result.get("synthesis", {}) if isinstance(result, dict) else {}
            if not isinstance(synthesis, dict):
                synthesis = {}
            items = synthesis.get("items", [])

            lines.append(f"### {label}")
            lines.append("```")
            if items:
                for item in items:
                    lines.append(str(item))
            else:
                lines.append("(no items returned)")
            lines.append("```\n")

    output = "\n".join(lines)
    with open(output_path, "w", encoding="utf-8") as f:
        f.write(output)

    print(f"Written {output_path} ({len(sections)} comparisons)")


def main() -> None:
    parser = argparse.ArgumentParser(description="Generate RESULTS.md from comparison JSON files.")
    parser.add_argument(
        "data_dir",
        nargs="?",
        default="data",
        help="Directory containing comparison_*.json files (default: data)",
    )
    parser.add_argument(
        "--output",
        default="RESULTS.md",
        help="Output markdown file path (default: RESULTS.md)",
    )
    args = parser.parse_args()
    generate(args.data_dir, args.output)


if __name__ == "__main__":
    main()
