import re
import json
import requests
import anthropic
from types import SimpleNamespace
from dotenv import load_dotenv

from scrape_byLLM import ScrapeByLLM
from comparison_parameters import ComparisonParams

load_dotenv()

MODEL = "claude-sonnet-4-6"
MAX_CHARS = 200000
HTML_SAMPLE_SIZE = 6000

PLAN_SCHEMA = (
    "Return ONLY a JSON object with these fields:\n"
    "  strategy: 'preset' or 'custom'\n"
    "  patterns: list of Python re-compatible regex strings\n"
    "  on: 'html' or 'text'\n"
    "  window: int (characters of context each side of a match)\n"
    "  notes: string (brief rationale, empty if none)"
)

_client = anthropic.Anthropic()


def _build_schemas(params: ComparisonParams) -> tuple[str, str]:
    synthesis_schema = (
        "Return ONLY a JSON object with:\n"
        "  summary: string summarising what was found\n"
        f"  items: list of strings, {params.items_format}\n"
        "  notes: string (caveats or empty string)\n"
        "No markdown, no explanation — raw JSON only."
    )
    output_schema = (
        "Return ONLY a JSON object with these exact fields:\n"
        "  pattern: string (type of data extracted, e.g. 'tables')\n"
        "  query: string (the original query, verbatim)\n"
        "  strategy: string ('preset' or 'custom')\n"
        "  on: string ('html' or 'text')\n"
        "  patterns: list of strings (regex patterns used, or empty list)\n"
        "  results: list containing one object with:\n"
        "    source: the URL string\n"
        "    snippets: list of strings, one per extracted row/item\n"
        "  synthesis: object with:\n"
        "    summary: string summarising what was found\n"
        f"    items: list of strings, {params.items_format}\n"
        "    notes: string (caveats or empty string)\n\n"
        "No markdown, no explanation — raw JSON only."
    )
    return synthesis_schema, output_schema


def _llm_json(prompt: str, max_tokens: int = 1024) -> dict:
    response = _client.messages.create(
        model=MODEL,
        max_tokens=max_tokens,
        messages=[{"role": "user", "content": prompt}],
    )
    text = response.content[0].text.strip()
    m = re.search(r"\{[\s\S]*\}", text)
    return json.loads(m.group()) if m else {}


def via_anthropic_direct(params: ComparisonParams, output_schema: str) -> dict:
    response = _client.messages.create(
        model=MODEL,
        max_tokens=4096,
        messages=[
            {
                "role": "user",
                "content": (
                    f"Fetch this webpage and extract the requested data.\n\n"
                    f"URL: {params.url}\n"
                    f"Query: {params.query}\n\n"
                    f"{output_schema}"
                ),
            }
        ],
        tools=[{"type": "web_fetch_20260209", "name": "web_fetch"}],
    )
    parts = []
    for block in response.content:
        if block.type == "text":
            parts.append(block.text)
    text = "\n".join(parts)
    m = re.search(r"\{[\s\S]*\}", text)
    return json.loads(m.group()) if m else {"raw": text}


def via_byllm(params: ComparisonParams) -> dict:
    with ScrapeByLLM(synthesize=True) as scraper:
        return scraper.get_all(source=params.url, query=params.query)


def via_direct_byllm(params: ComparisonParams) -> dict:
    from scrape_byLLM.direct_byllm import fetch_and_extract  # type: ignore[import]
    return fetch_and_extract(url=params.url, query=params.query, max_chars=MAX_CHARS)


def via_direct_pipeline(params: ComparisonParams, synthesis_schema: str) -> dict:
    from scrape_byLLM.executor import extract, dedup  # type: ignore[import]
    from scrape_byLLM.presets import preset_table  # type: ignore[import]

    presets = preset_table()
    pattern_names = list(presets.keys())

    pattern = _client.messages.create(
        model=MODEL,
        max_tokens=20,
        messages=[{
            "role": "user",
            "content": (
                "Return the single pattern name from this list that best matches "
                "what the user wants to extract. Return exactly one name — "
                "no explanation, no punctuation.\n\n"
                f"Available patterns: {pattern_names}\n\nQuery: {params.query}"
            ),
        }],
    ).content[0].text.strip()
    if pattern not in presets:
        pattern = "text"

    html = requests.get(params.url, headers={"User-Agent": "scrape-byLLM"}, timeout=20).text[:MAX_CHARS]
    plan_data = _llm_json(
        f"Decide how to extract the requested query from HTML.\n"
        f"Prefer selecting and lightly parameterising a pattern from available_regexes.\n"
        f"{PLAN_SCHEMA}\n\n"
        f"pattern: {pattern}\n"
        f"query: {params.query}\n"
        f"available_regexes: {json.dumps(presets)}\n"
        f"sample_html:\n{html[:HTML_SAMPLE_SIZE]}",
        max_tokens=4096,
    )
    plan = SimpleNamespace(
        strategy=plan_data.get("strategy", "custom"),
        patterns=plan_data.get("patterns", [presets.get(pattern, "")]),
        on=plan_data.get("on", "html"),
        window=int(plan_data.get("window", 200)),
        notes=plan_data.get("notes", ""),
    )

    snippets = dedup(extract(plan, html, plan.window))

    flat = "\n".join(f"[{params.url}] {s}" for s in snippets)
    synthesis_data = _llm_json(
        f"Read the flat snippet text from every scraped page and extract the information "
        f"the user is after. Infer intent from the original query. Return a clean, structured "
        f"synthesis without fabricating facts not present in the snippets.\n"
        f"{synthesis_schema}\n\n"
        f"query: {params.query}\npattern: {pattern}\nsnippets:\n{flat}",
        max_tokens=8096,
    )

    return {
        "pattern": pattern,
        "query": params.query,
        "strategy": plan.strategy,
        "on": plan.on,
        "patterns": plan.patterns,
        "page_count": 1,
        "llm_calls": 3,
        "results": [{"source": params.url, "snippets": snippets}],
        "synthesis": {
            "summary": synthesis_data.get("summary", ""),
            "items": synthesis_data.get("items", []),
            "notes": synthesis_data.get("notes", ""),
        },
    }


GRADE_SCHEMA = (
    "Return ONLY a JSON object with:\n"
    "  grades: list of objects, one per method, each with:\n"
    "    name: string, the method name exactly as given (e.g. 'direct_anthropic')\n"
    "    verdict: string, exactly 'PASS' or 'FAIL'\n"
    "    reasoning: string, one concise sentence justifying the verdict\n"
    "No markdown, no explanation outside the JSON — raw JSON only."
)

_GRADE_KEYS = ("direct_anthropic", "byllm", "direct_byllm", "direct_pipeline")


def _method_output_text(result: dict) -> str:
    synthesis = result.get("synthesis", {}) if isinstance(result, dict) else {}
    if not isinstance(synthesis, dict):
        synthesis = {}
    items = synthesis.get("items", [])
    if items:
        return "\n".join(str(item) for item in items)
    return "(no items returned)"


def grade_methods(params: ComparisonParams, result: dict) -> list[dict]:
    """Grade every method's output for this comparison in a single LLM call,
    rather than one call per method."""
    methods_block = "\n\n".join(
        f"### {key}\n{_method_output_text(result.get(key, {}))}"
        for key in _GRADE_KEYS
    )
    prompt = (
        "You are grading web-scraping extraction outputs from a known failure-mode test case.\n\n"
        f"Query: {params.query}\n"
        f"What correct behavior looks like: {params.description}\n\n"
        "Below are the outputs of four independent extraction methods for the same query. "
        "Grade each PASS or FAIL: PASS means the method returned the semantically correct answer "
        "and avoided the failure mode described above; FAIL means it fabricated data, returned the "
        "wrong value, or otherwise fell into the described failure mode — even if the output looks "
        "structurally well-formed.\n\n"
        f"{methods_block}\n\n"
        f"{GRADE_SCHEMA}"
    )
    data = _llm_json(prompt, max_tokens=2048)
    grades = data.get("grades", [])
    return grades if isinstance(grades, list) else []


def merge_grades(result: dict, grades: list[dict]) -> dict:
    """Fold grade verdicts back into each method's result object in place."""
    by_name = {
        str(g["name"]): g
        for g in grades
        if isinstance(g, dict) and g.get("name")
    }

    for key in _GRADE_KEYS:
        grade = by_name.get(key, {})
        method_result = result.get(key)
        if isinstance(method_result, dict):
            method_result["grade"] = {
                "verdict": str(grade.get("verdict", "UNKNOWN")),
                "reasoning": str(grade.get("reasoning", "")),
            }
    return result


def run_comparison(params: ComparisonParams, verbose: bool = False) -> dict:
    synthesis_schema, output_schema = _build_schemas(params)

    if verbose:
        print("  [1/4] direct Anthropic API...")
    direct_result = via_anthropic_direct(params, output_schema)

    if verbose:
        print("  [2/4] byLLM...")
    byllm_result = via_byllm(params)

    if verbose:
        print("  [3/4] direct byLLM...")
    direct_byllm_result = via_direct_byllm(params)

    if verbose:
        print("  [4/4] direct pipeline...")
    pipeline_result = via_direct_pipeline(params, synthesis_schema)

    result = {
        "url": params.url,
        "query": params.query,
        "model": MODEL,
        "category": params.category,
        "failure_type": params.failure_type,
        "description": params.description,
        "direct_anthropic": direct_result,
        "byllm": byllm_result,
        "direct_byllm": direct_byllm_result,
        "direct_pipeline": pipeline_result,
    }

    if verbose:
        print("  [grading] scoring outputs against description...")
    grades = grade_methods(params, result)
    merge_grades(result, grades)

    return result
