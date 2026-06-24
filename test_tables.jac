include scraper;

with entry {
    print("--- list[Table] via include ---");
    thtml = "<table><caption>Pets</caption><tr><th>Name</th><th>Age</th></tr><tr><td>Rex</td><td>3</td></tr></table>";
    for t in extract_tables(thtml) { print(t.caption, t.headers, t.rows); }
}
