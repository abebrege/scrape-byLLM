from dataclasses import dataclass
from typing import Literal


@dataclass
class ComparisonParams:
    name: str
    url: str
    query: str
    items_format: str
    category: int
    failure_type: Literal["structural", "semantic", "both"]
    description: str = ""

    @property
    def output_file(self) -> str:
        return f"data/comparison_{self.name}.json"


COMPARISONS: dict[str, ComparisonParams] = {
    "population_density": ComparisonParams(
        name="population_density",
        url="https://en.wikipedia.org/wiki/Population_density",
        query="return the population of each country from the tables on this page",
        items_format="one per country in 'Country: population' format",
        category=4,
        failure_type="both",
        description=(
            "Baseline dispersed-extraction case: multiple tables spread across a long page. "
            "Structural failure is a partial list that looks complete."
        ),
    ),
    "price_disambiguation": ComparisonParams(
        name="price_disambiguation",
        url="https://en.wikipedia.org/wiki/PlayStation_5",
        query="what is the price of the PlayStation 5?",
        items_format="one per SKU or regional variant in 'Variant: price (currency)' format",
        category=1,
        failure_type="semantic",
        description=(
            "Multiple prices on-page: launch price, disc edition, digital edition, regional variants. "
            "Model must surface all variants rather than picking one confidently."
        ),
    ),
    "computed_value": ComparisonParams(
        name="computed_value",
        url="https://en.wikipedia.org/wiki/Concorde",
        query="what was Concorde's maximum speed in miles per hour?",
        items_format="one entry: 'Maximum speed: <value> mph (converted from <original value and unit>)'",
        category=2,
        failure_type="semantic",
        description=(
            "Speed is given in km/h and Mach; the answer in mph requires a unit conversion "
            "not present on the page. Regex-plan can extract the raw number but cannot derive mph."
        ),
    ),
    "merged_table_headers": ComparisonParams(
        name="merged_table_headers",
        url="https://en.wikipedia.org/wiki/List_of_countries_by_GDP_(nominal)",
        query="what is the GDP of Germany, France, and Japan according to the IMF?",
        items_format="one per country in 'Country: GDP in USD millions (IMF, year)' format",
        category=3,
        failure_type="semantic",
        description=(
            "GDP table uses multi-level column headers (source × year) with colspan. "
            "Markdown flattening destroys cell-to-header mapping; model returns a value "
            "from roughly the right region of the table."
        ),
    ),
    "dispersed_extract_all": ComparisonParams(
        name="dispersed_extract_all",
        url="https://en.wikipedia.org/wiki/List_of_Academy_Award_for_Best_Picture_winners",
        query="return all Best Picture Oscar winners from 2010 to 2024",
        items_format="one per year in 'Year: Film Title' format",
        category=4,
        failure_type="both",
        description=(
            "15 entries dispersed across a very long table. "
            "Classic truncation failure: model returns a partial list that looks complete."
        ),
    ),
    "absent_data": ComparisonParams(
        name="absent_data",
        url="https://en.wikipedia.org/wiki/Albert_Einstein",
        query="what is Albert Einstein's email address and phone number?",
        items_format="one per requested field in 'Field: value' format, or 'Field: NOT FOUND' if absent",
        category=5,
        failure_type="semantic",
        description=(
            "Requested fields do not exist anywhere on the page. Correct answer is null/not-found. "
            "Failure is fabrication of a plausible-looking value — structurally valid, semantically catastrophic."
        ),
    ),
    "implicit_relational": ComparisonParams(
        name="implicit_relational",
        url="https://en.wikipedia.org/wiki/OpenAI",
        query="who founded OpenAI and who is the current CEO?",
        items_format="one per person in 'Role: Name' format",
        category=6,
        failure_type="semantic",
        description=(
            "CEO role may be described implicitly ('leads as chief executive'). "
            "Requires distinguishing co-founder from current leader; regex-plan cannot resolve this."
        ),
    ),
    "format_ambiguity": ComparisonParams(
        name="format_ambiguity",
        url="https://en.wikipedia.org/wiki/Volkswagen",
        query="what is Volkswagen's annual revenue in euros for the most recent reported year?",
        items_format="one entry: 'Revenue: <normalized numeric value> EUR (year: <year>, raw: <original string>)'",
        category=8,
        failure_type="semantic",
        description=(
            "European financial figures use period-as-thousands-separator and comma-as-decimal "
            "(e.g. 293.000 = 293,000 not 293.0). Tests whether the model normalizes or silently mis-parses."
        ),
    ),
    "distractor_contamination": ComparisonParams(
        name="distractor_contamination",
        url="https://en.wikipedia.org/wiki/2020_United_States_presidential_election",
        query="what percentage of the popular vote did Joe Biden receive in the 2020 presidential election?",
        items_format="one entry: 'Biden national popular vote share: <exact percentage>' citing the specific table or section",
        category=9,
        failure_type="semantic",
        description=(
            "Page contains dozens of vote percentages (state results, third-party candidates, "
            "Electoral College tallies). Model must return the top-line national popular vote share, "
            "not a state result or an opponent figure."
        ),
    ),
}

DEFAULT_COMPARISON = "population_density"
