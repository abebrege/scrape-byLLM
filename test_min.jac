import from byllm.lib { Model }

glob llm = Model(model_name="anthropic/claude-sonnet-4-6");

obj Table {
    has headers: list[str];
    has rows: list[list[str]];
    has caption: str = "";
}

sem Table.headers = "Column header cells, left to right.";
sem Table.rows = "Data rows; each row is a list of cell strings.";

"""Extract every data table on the page as structured rows and headers."""
def extract_tables(html: str) -> list[Table] by llm(temperature=0.0);

with entry {
    thtml = "<table><caption>Pets</caption><tr><th>Name</th><th>Age</th></tr><tr><td>Rex</td><td>3</td></tr></table>";
    for t in extract_tables(thtml) { print(t.caption, "|", t.headers, "|", t.rows); }
}
