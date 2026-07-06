def preset_table() -> dict[str, str] {
    return {
        # ── structural / HTML ─────────────────────────────────────────────────
        "links":         "<a\\b[^>]*?href=[\"']([^\"']+)[\"']",
        "links_text":    "<a\\b[^>]*?>([\\s\\S]*?)(?:</a>|$)",
        "images":        "<img\\b[^>]*?(?:src|data-src|data-lazy|data-lazy-src|data-original|data-img|data-echo|data-srcset)=[\"']([^\"']+)[\"']",
        "iframes":       "<iframe\\b[^>]*?src=[\"']([^\"']+)[\"']",
        "tables":        "<table\\b[\\s\\S]*?(?:</table>|$)",
        "headings":      "<h([1-6])\\b[^>]*>([\\s\\S]*?)(?:</h\\1>|$)",
        "buttons":       "<button\\b[^>]*>([\\s\\S]*?)(?:</button>|$)|<input\\b[^>]*?type=[\"'](?:submit|button)[\"'][^>]*>",
        "code":          "<(?:code|pre)\\b[^>]*>([\\s\\S]*?)(?:</(?:code|pre)>|$)",
        "charts":        "<(?:canvas|svg)\\b[\\s\\S]*?(?:</(?:canvas|svg)>|$)",
        "forms":         "<form\\b[^>]*>[\\s\\S]*?(?:</form>|$)",
        "scripts":       "<script\\b[^>]*?src=[\"']([^\"']+)[\"']",
        "css":           "<link\\b(?=[^>]*rel=[\"']stylesheet[\"'])[^>]*?href=[\"']([^\"']+)[\"']",

        # ── embedded rich media ───────────────────────────────────────────────
        "video":         "<(?:video|source)\\b[^>]*?src=[\"']([^\"']+)[\"']",
        "video_embeds":  "<iframe\\b[^>]*?src=[\"']([^\"']*(?:youtube\\.com/embed|youtu\\.be|player\\.vimeo\\.com|dailymotion\\.com/embed|player\\.twitch\\.tv|loom\\.com/embed|wistia\\.com/embed)[^\"']*)[\"']",

        # ── structured / semantic metadata ────────────────────────────────────
        "jsonld":        "<script\\b[^>]*application/ld\\+json[^>]*>([\\s\\S]*?)(?:</script>|$)",
        "metadata":      "<meta\\b[^>]*?(?:name|property)=[\"']([^\"']+)[\"'][^>]*?content=[\"']([^\"']*)[\"']",

        # ── contact / entity ─────────────────────────────────────────────────
        "emails":        "[A-Za-z0-9._%+\\-]+@[A-Za-z0-9.\\-]+\\.[A-Za-z]{2,}",

        # covers common formats: +1 (800) 555-1234, 800.555.1234, ext 42, x42
        "phones":        "\\+?(?:\\d{1,3}[\\s.\\-]?)?(?:\\(?\\d{2,4}\\)?[\\s.\\-]?){1,3}\\d{3,4}(?:[\\s.\\-]?(?:ext\\.?|x|#)\\s?\\d{1,6})?",

        # prefix: $19.99 / USD 19.99 — suffix: 19.99€ / 19.99 EUR
        # symbols: $ € £ ¥ ₹ ₩ ₪ ₨ ₦ ₴ ₱ ₿
        # ISO codes: 50 major currencies + BTC/ETH
        "prices":        "(?:[$€£¥₹₩₪₨₦₴₱₿]|USD|EUR|GBP|JPY|CAD|AUD|CHF|CNY|INR|MXN|BRL|KRW|SGD|HKD|NOK|SEK|DKK|NZD|ZAR|RUB|TRY|PLN|THB|IDR|HUF|CZK|ILS|CLP|PHP|AED|COP|SAR|MYR|RON|UAH|PKR|EGP|NGN|VND|BDT|ETB|KES|GHS|MAD|TZS|XOF|XAF|BTC|ETH)\\s?\\d[\\d,.]*(?:\\.\\d{1,2})?|\\d[\\d,.]*(?:\\.\\d{1,2})?\\s?(?:[$€£¥₹₩₪₨₦₴₱₿]|USD|EUR|GBP|JPY|CAD|AUD|CHF|CNY|INR|MXN|BRL|KRW|SGD|HKD|NOK|SEK|DKK|NZD|ZAR|RUB|TRY|PLN|THB|IDR|HUF|CZK|ILS|CLP|PHP|AED|COP|SAR|MYR|RON|UAH|PKR|EGP|NGN|VND|BDT|ETB|KES|GHS|MAD|TZS|XOF|XAF|BTC|ETH)",

        # ── date & time ───────────────────────────────────────────────────────
        # ISO 8601: 2024-01-15  |  numeric: 01/15/2024 15/01/2024  |  written: Jan 15, 2024 / 15 January 2024
        "dates":         "\\b(?:\\d{4}[-/.]\\d{1,2}[-/.]\\d{1,2}|\\d{1,2}[-/.]\\d{1,2}[-/.]\\d{2,4}|(?:January|February|March|April|May|June|July|August|September|October|November|December|Jan|Feb|Mar|Apr|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\\.?\\s+\\d{1,2}(?:st|nd|rd|th)?,?\\s+\\d{4}|\\d{1,2}(?:st|nd|rd|th)?\\s+(?:January|February|March|April|May|June|July|August|September|October|November|December|Jan|Feb|Mar|Apr|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\\.?(?:,?\\s+\\d{4})?)\\b",

        # ── network / tech ────────────────────────────────────────────────────
        "ips":           "\\b(?:(?:25[0-5]|2[0-4]\\d|[01]?\\d{1,2})\\.){3}(?:25[0-5]|2[0-4]\\d|[01]?\\d{1,2})\\b",
        "urls":          "https?://[A-Za-z0-9\\-._~:/?#\\[\\]@!$&'()*+,;=%]+",

        # ── social / community ────────────────────────────────────────────────
        "social":        "(?:https?://)?(?:www\\.)?(?:twitter\\.com|x\\.com|facebook\\.com|instagram\\.com|linkedin\\.com|github\\.com|youtube\\.com|tiktok\\.com|pinterest\\.com|reddit\\.com|threads\\.net|snapchat\\.com|mastodon\\.social)/[A-Za-z0-9_.@\\-/%?=&+#]+",
        "hashtags":      "(?:^|\\s)#([A-Za-z][A-Za-z0-9_]{1,49})\\b",

        # ── location ──────────────────────────────────────────────────────────
        "addresses":     "\\d{1,5}\\s+[A-Z][A-Za-z0-9\\s.'-]{2,50}(?:Street|St|Avenue|Ave|Boulevard|Blvd|Road|Rd|Drive|Dr|Lane|Ln|Court|Ct|Place|Pl|Way|Highway|Hwy|Circle|Cir|Terrace|Ter|Parkway|Pkwy)\\.?(?:,\\s*(?:Suite|Ste|Apt|Unit|#)?\\s*[A-Za-z0-9]+)?(?:,\\s*[A-Za-z][A-Za-z\\s]+,\\s*[A-Z]{2}(?:\\s+\\d{5}(?:-\\d{4})?)?)?",

        # ── full visible text ──────────────────────────────────────────────────
        "text":          ""
    };
}
