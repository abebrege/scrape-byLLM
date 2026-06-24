import from scraper { fetch_page }

with entry {
    html = fetch_page("https://example.com");
    print(f"fetched {len(html)} chars");
    print(html[:200]);
}
