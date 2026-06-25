"""scrape-byllm entry point.

Only three things live here:
  1. byLLM functions whose return types are custom obj/enum — byLLM 0.6.17
     requires these to be compiled in the entry module.
  2. scrape(): the public interface that routes via choose_target and delegates
     to lib/scrape.jac and ml/.
  3. The `with entry` block.

Everything else (types, sems, dispatch, formatting, LLM helpers) lives in
lib/scrape.jac and ml/.
"""

import from byllm.lib { Model }
import from dotenv { load_dotenv }
import from lib.scraper { fetch_page, quit_driver }
import from lib.scrape { Table, Article, Target, dispatch, format_tables }
import from ml.process { filter_items, pick_one }
import from ml.selectors { expects_list }

glob llm = Model(model_name="anthropic/claude-sonnet-4-6");


# ── byLLM functions with custom return types (must live in entry module) ───────

"""Given raw HTML and a query, return only the requested information as clean text."""
def extract(html: str, query: str) -> str by llm(temperature=0.0);

"""Extract every data table on the page as structured rows and headers."""
def extract_tables(html: str) -> list[Table] by llm(temperature=0.0);

"""Extract each bulleted or numbered list on the page as a list of item strings."""
def extract_lists(html: str) -> list[list[str]] by llm(temperature=0.0);

"""Return the main readable article/body content, stripped of nav, ads, and boilerplate."""
def extract_body(html: str) -> Article by llm(temperature=0.0);

"""Pick the single best page-extraction target for the user's natural-language query."""
def choose_target(query: str) -> Target by llm(temperature=0.0);


# ── public interface ───────────────────────────────────────────────────────────

def scrape(url: str, query: str) -> str {
    target = choose_target(query);

    if target == Target.CODE_SNIPPETS or target == Target.BODY_TEXT {
        return extract(fetch_page(url), query);
    }

    if target == Target.TABLE_ROWS {
        return format_tables(extract_tables(fetch_page(url)));
    }

    raw: list[str] = dispatch(target, url, query);
    capped: list[str] = [];
    for s in raw[:300] {
        if len(s) > 500 {
            capped.append(s[:500]);
        } else {
            capped.append(s);
        }
    }

    if target == Target.TITLE or not expects_list(query) {
        return pick_one(query, capped);
    }
    return "\n".join(filter_items(query, capped));
}

def get_tables(url: str) -> list[Table] {
    return extract_tables(fetch_page(url));
}

def get_lists(url: str) -> list[list[str]] {
    return extract_lists(fetch_page(url));
}

def get_body(url: str) -> Article {
    return extract_body(fetch_page(url));
}


with entry {
    load_dotenv();

    url = "https://doc.rust-lang.org/book/ch03-01-variables-and-mutability.html";
    print(scrape(url, "the code snippets from this page, as clean text"));

    quit_driver();
}
