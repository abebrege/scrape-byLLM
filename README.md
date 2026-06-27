# scrape-byLLM

A library for web scraping, written in [Jac](https://jaseci.org)
with [byLLM](https://pypi.org/project/byllm/).

```
fetch -> planner -> executor (determine regex byLLM) -> [synthesize byLLM] -> [write]
```

## Install

Requires Python ≥ 3.11 and Google Chrome (only for `render=True` pages).
```bash

uv pip install -e .
```
or
```bash
pip install -e .
```

This installs the `scrape_byLLM` package and its dependencies (jaclang, byllm,
selenium, requests, beautifulsoup4, lxml, python-dotenv).

## Setup

byLLM needs an API key for the configured model (`anthropic/claude-sonnet-4-6`,
set in `jac.toml`). Put it in a `.env` file at the project root:

```
ANTHROPIC_API_KEY=sk-ant-...
```

`main.jac` calls `load_dotenv()`, so the key is picked up automatically.

## Basic use

Run the example entrypoint:

```bash
jac run main.jac
```

`main.jac` is intentionally tiny — it just calls the library:

```jac
import from dotenv { load_dotenv }
import from scrape_byLLM.scraper { get_all_prices, quit_driver }

with entry {
    load_dotenv();
    out = get_all_prices(
        source="https://example.com",
        query="get all crypto modules exposed by this library",
        opts={"output": "data/out.json", "synthesize": True}
    );
    print(out);
    quit_driver();
}
```

### The API

Import any `get_all_*` helper from `scrape_byLLM.scraper` (or directly from
`scrape_byLLM`):

```
get_all(thing, source, query="", opts={})   # generic
get_all_links / get_all_images / get_all_prices / get_all_emails /
get_all_phones / get_all_tables / get_all_headings / get_all_text /
get_all_charts / get_all_code                # one preset per "thing"
```

- **source** — a URL, a list of URLs, raw HTML, or plain text (mixed lists are fine).
- **query** — optional natural-language description. When given, the LLM compiles
  a custom plan. When omitted, the built-in preset regex for that `thing` is used
  (no LLM call).

### Options (`opts`)

| key          | type        | default | effect                                                     |
|--------------|-------------|---------|------------------------------------------------------------|
| `render`     | bool        | `False` | Fetch via headless Chrome instead of `requests` (JS pages).|
| `timeout`    | int         | `20`    | Per-request timeout in seconds (static fetch).             |
| `dedup`      | bool        | `True`  | Drop duplicate snippets per page.                          |
| `synthesize` | bool        | `False` | Run one extra LLM pass; adds a structured `synthesis` block.|
| `output`     | str \| bool | —       | Also write the result as JSON. `True` → `data/out.json`; a string → that path. |

### Output

Every call **returns a dict** and writes nothing by default. Writing is an opt-in
side effect via `opts["output"]` — the returned value is identical either way:

```jac
out = get_all_links(source="https://example.com");                    # returns only
out = get_all_links(source="...", opts={"output": True});             # + data/out.json
out = get_all_links(source="...", opts={"output": "out/links.json"}); # + custom path
```

Result shape:

```json
{
  "thing": "prices",
  "query": "...",
  "strategy": "preset | custom",
  "on": "html | text",
  "patterns": ["..."],
  "page_count": 1,
  "llm_calls": 2,
  "results": [{ "source": "...", "snippets": ["..."] }],
  "synthesis": { "summary": "...", "items": ["..."], "notes": "..." }
}
```
