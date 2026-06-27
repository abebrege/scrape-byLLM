"""RegexPlan type for scrape-byllm.

The byLLM function that produces RegexPlan must live in main.jac (entry module
constraint). This file holds only the data type and its sem annotations so that
lib/executor.jac can import and type-annotate against it.
"""


"""A compiled, reusable extraction plan. Produced once by the LLM, cached and
reused deterministically across every subsequent page."""
obj RegexPlan {
    has strategy: str;
    has patterns: list[str];
    has on: str;
    has ctx: int = 200;
    has notes: str = "";
}

sem RegexPlan = "A compiled regex extraction plan produced once and applied to every page without further LLM calls.";
sem RegexPlan.strategy = "How the plan was produced: 'preset' (selected from known HTML patterns) or 'custom' (LLM-generated regex for semantic content such as crypto tickers or person names).";
sem RegexPlan.patterns = "Python re-compatible regex strings to run against the page. Capture groups are optional; the executor captures the full match plus ctx chars of context either side.";
sem RegexPlan.on = "Surface to run patterns against: 'html' for structural targets (links, images, tables) or 'text' for semantic targets where visible text is more reliable than markup.";
sem RegexPlan.ctx = "Characters of surrounding context to capture on each side of a match (the ±N window). Default 200.";
sem RegexPlan.notes = "Planner rationale or debug notes; empty string if the planner provided none.";
