import from requests { get }
import from requests.exceptions { RequestException }
import from selenium { webdriver }
import from selenium.webdriver.chrome.options { Options }
import from time { time, sleep }
import from scrape_byLLM.robots { is_allowed, get_crawl_delay }

glob _driver_holder: list[any] = [];
glob _last_request_time: list[float] = [0.0];

glob _RETRYABLE: list[int] = [429, 502, 503, 504];


def _get_driver() -> any {
    if not _driver_holder {
        opts = Options();
        opts.add_argument("--headless=new");
        opts.add_argument("--no-sandbox");
        opts.add_argument("--disable-dev-shm-usage");
        opts.add_argument("--disable-gpu");
        opts.add_argument("--window-size=1920,1080");
        driver: any = webdriver.Chrome(options=opts);
        driver.set_page_load_timeout(30);
        _driver_holder.append(driver);
    }
    return _driver_holder[0];
}


def _fetch_rendered(url: str, max_chars: int = 40000) -> str {
    driver: any = _get_driver();
    driver.get(url);
    clean_js = "for (const el of document.querySelectorAll('script, style, noscript')) { el.remove(); } return document.documentElement.outerHTML;";
    html: str = str(driver.execute_script(clean_js));
    if len(html) > max_chars {
        return html[:max_chars];
    }
    return html;
}


def _http_get(url: str, timeout: int, headers: dict, max_retries: int = 3) -> str {
    delay: float = 1.0;
    last_exc: any = None;

    for attempt in range(max_retries) {
        try {
            resp: any = get(url, timeout=timeout, headers=headers);
            if resp.status_code in _RETRYABLE and attempt < max_retries - 1 {
                sleep(delay);
                delay = delay * 2.0;
                continue;
            }
            resp.raise_for_status();
            return str(resp.text);
        } except RequestException as e {
            last_exc = e;
            if attempt < max_retries - 1 {
                sleep(delay);
                delay = delay * 2.0;
            }
        }
    }
    if last_exc is not None {
        raise last_exc;
    }
    return "";
}


def quit_driver() {
    if _driver_holder {
        _driver_holder[0].quit();
        _driver_holder.clear();
    }
}


def fetch_one(
    url: str,
    render: bool = False,
    timeout: int = 20,
    max_chars: int = 40000,
    respect_robots: bool = True,
    user_agent: str = "scrape-byLLM",
    extra_headers: dict = {},
    rate_limit: float = 0.0
) -> str {
    if not is_allowed(url, user_agent, respect_robots, timeout) {
        raise ValueError("Blocked by robots.txt: " + url);
    }

    crawl_delay: float = get_crawl_delay(url, user_agent);
    effective_delay: float = rate_limit;
    if crawl_delay > effective_delay {
        effective_delay = crawl_delay;
    }
    if effective_delay > 0.0 {
        now: float = time();
        elapsed: float = now - _last_request_time[0];
        if elapsed < effective_delay {
            sleep(effective_delay - elapsed);
        }
    }
    _last_request_time[0] = time();

    if render {
        return _fetch_rendered(url, max_chars);
    }

    headers: dict = {"User-Agent": user_agent};
    headers.update(extra_headers);
    raw: str = _http_get(url, timeout, headers);
    if len(raw) > max_chars {
        return raw[:max_chars];
    }
    return raw;
}


def fetch_many(urls: list[str], render: bool = False, timeout: int = 20, max_chars: int = 40000) -> list[dict] {
    results: list[dict] = [];
    for url in urls {
        html: str = fetch_one(url, render, timeout, max_chars);
        results.append({"url": url, "html": html});
    }
    return results;
}


def normalize_source(source: any) -> list[dict] {
    if isinstance(source, list) {
        items: list[dict] = [];
        for s in source {
            items = items + normalize_source(s);
        }
        return items;
    }
    if isinstance(source, str) {
        if source.startswith("http://") or source.startswith("https://") {
            return [{"url": source, "html": ""}];
        }
        return [{"url": "", "html": source}];
    }
    return [];
}
