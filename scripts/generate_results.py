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

_BADGES = {"PASS": "PASS", "FAIL": "FAIL"}


def _badge(verdict: str) -> str:
    return _BADGES.get(verdict, "N/A")


def _grade(result: dict) -> dict:
    grade = result.get("grade", {}) if isinstance(result, dict) else {}
    return grade if isinstance(grade, dict) else {}


def _summary_table(sections: list[tuple[str, dict]]) -> list[str]:
    lines = ["## Summary\n"]
    header = ["Test"] + [label for _, label in RUN_KEYS]
    lines.append("| " + " | ".join(header) + " |")
    lines.append("|" + "|".join(["---"] * len(header)) + "|")

    totals = {key: 0 for key, _ in RUN_KEYS}
    total_tests = len(sections)

    for name, d in sections:
        title = name.replace("_", " ").title()
        row = [title]
        for key, _ in RUN_KEYS:
            verdict = _grade(d.get(key, {})).get("verdict", "")
            if verdict == "PASS":
                totals[key] += 1
            row.append(_badge(verdict))
        lines.append("| " + " | ".join(row) + " |")

    totals_row = ["**Totals**"] + [
        f"**{totals[key]}/{total_tests}**" for key, _ in RUN_KEYS
    ]
    lines.append("| " + " | ".join(totals_row) + " |")
    lines.append("")
    return lines


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
    lines.extend(_summary_table(sections))

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
            grade = _grade(result)
            verdict = grade.get("verdict", "")
            reasoning = grade.get("reasoning", "")

            lines.append(f"### {label} — {_badge(verdict)}")
            if reasoning:
                lines.append(f"*{reasoning}*\n")
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
