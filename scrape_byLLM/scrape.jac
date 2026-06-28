import from scrape_byLLM.fetch { fetch_one }
import from scrape_byLLM.executor { strip_to_text }


obj Table {
    has headers: list[str];
    has rows: list[list[str]];
    has caption: str = "";
}

sem Table = "A single data table extracted from a web page.";
sem Table.headers = "Column header cells, left to right.";
sem Table.rows = "Data rows; each row is a list of cell strings aligned to headers.";
sem Table.caption = "The table's title or caption; empty string if none.";


obj Article {
    has text: str;
    has title: str = "";
}

sem Article = "The main readable article extracted from a web page.";
sem Article.text = "The main body text, stripped of nav, ads, and boilerplate.";
sem Article.title = "The article or page title.";


enum Target {
    LINKS,
    LINK_TEXTS,
    PARAGRAPHS,
    HEADINGS,
    LIST_ITEMS,
    TABLE_ROWS,
    IMAGES,
    BUTTONS,
    TITLE,
    BODY_TEXT,
    CODE_SNIPPETS
}

sem Target.LINKS = "All hyperlink URLs (href) on the page. Use when the user wants links or URLs.";
sem Target.LINK_TEXTS = "Visible text of every anchor tag. Use when the user wants what links say, not where they go.";
sem Target.PARAGRAPHS = "Text of every paragraph element. Use for article or prose body content.";
sem Target.HEADINGS = "Text of every heading element h1-h6 in document order. Use for page outline, section titles, or structure.";
sem Target.LIST_ITEMS = "Text of every list item (li). Use for bulleted or numbered list content.";
sem Target.TABLE_ROWS = "Every table row as a list of cell strings. Use for tabular or grid data.";
sem Target.IMAGES = "src URL (or alt text) of every image. Use when the user wants images or media.";
sem Target.BUTTONS = "Visible text or value of every button and submit input. Use for interactive controls or calls-to-action.";
sem Target.TITLE = "The single page title string. Use when the user wants the page title or name.";
sem Target.BODY_TEXT = "The entire visible page text as one string. Use as a broad fallback for open-ended content questions.";
sem Target.CODE_SNIPPETS = "Code examples, code blocks, or programming snippets on the page. Use when the user wants code, samples, or technical demos.";


def format_tables(tables: list[Table]) -> str {
    lines: list[str] = [];
    for t in tables {
        if t.caption {
            lines.append(t.caption);
        }
        lines.append(" | ".join(t.headers));
        for row in t.rows {
            lines.append(" | ".join(row));
        }
        lines.append("");
    }
    return "\n".join(lines);
}
