"""byLLM selector helpers for scrape-byllm.

All functions here return primitive types (str, bool) so they are safe to
import from a non-entry module. byLLM 0.6.17 only builds the output schema
for custom obj/enum return types when the function is compiled in the entry
module — primitives have built-in schemas and work anywhere.

The Target enum and choose_target (which returns Target) therefore live in
main.jac, not here.
"""

import from byllm.lib { Model }

glob llm = Model(model_name="anthropic/claude-sonnet-4-6");


"""Given a natural-language description of page elements the user wants, produce a CSS selector string that targets exactly those elements."""
def css_for(query: str) -> str by llm(temperature=0.0);

"""Given a natural-language description of page elements the user wants, produce an XPath expression string that targets exactly those elements."""
def xpath_for(query: str) -> str by llm(temperature=0.0);

"""Return true if the user's query expects multiple results (a list), false if it expects a single value."""
def expects_list(query: str) -> bool by llm(temperature=0.0);
