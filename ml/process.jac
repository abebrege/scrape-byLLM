"""byLLM processing helpers for scrape-byllm.

All functions here return primitive types (str, list[str]) so they are safe
to import from a non-entry module. byLLM 0.6.17 only builds the output
schema for custom obj/enum return types in the entry module — list[str] and
str are built-in schemas that work in any imported module.
"""

import from byllm.lib { Model }

glob llm = Model(model_name="anthropic/claude-sonnet-4-6");


"""From a list of candidate strings scraped off a web page, return only the items that satisfy the user's natural-language request, cleaned and deduplicated. Return an empty list if no items match."""
def filter_items(query: str, items: list[str]) -> list[str] by llm(temperature=0.0);

"""From scraped page content provided as a list of strings, return the single value that best answers the user's natural-language request as plain text."""
def pick_one(query: str, items: list[str]) -> str by llm(temperature=0.0);
