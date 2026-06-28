import from urllib.robotparser { RobotFileParser }
import from urllib.parse { urlparse }
import from requests { get }

glob _robots_cache: dict[str, any] = {};


def _origin(url: str) -> str {
    parsed: any = urlparse(url);
    return str(parsed.scheme) + "://" + str(parsed.netloc);
}


def _fetch_robots(origin: str, user_agent: str, timeout: int) -> any {
    rp: any = RobotFileParser();
    rp.set_url(origin + "/robots.txt");
    try {
        resp: any = get(
            origin + "/robots.txt",
            timeout=timeout,
            headers={"User-Agent": user_agent}
        );
        if resp.status_code == 200 {
            rp.parse(resp.text.splitlines());
        }
    } except Exception {
        # Robots.txt unreachable: fail open (allow all).
    }
    rp.modified();
    return rp;
}


def _get_robots(url: str, user_agent: str = "scrape-byLLM", timeout: int = 10) -> any {
    origin: str = _origin(url);
    if origin not in _robots_cache {
        _robots_cache[origin] = _fetch_robots(origin, user_agent, timeout);
    }
    return _robots_cache[origin];
}


def is_allowed(
    url: str,
    user_agent: str = "scrape-byLLM",
    respect_robots: bool = True,
    timeout: int = 10
) -> bool {
    if not respect_robots {
        return True;
    }
    if not url.startswith("http") {
        return True;
    }
    rp: any = _get_robots(url, user_agent, timeout);
    return bool(rp.can_fetch(user_agent, url));
}


def get_crawl_delay(url: str, user_agent: str = "scrape-byLLM") -> float {
    if not url.startswith("http") {
        return 0.0;
    }
    rp: any = _get_robots(url, user_agent);
    delay: any = rp.crawl_delay(user_agent);
    if delay is None {
        return 0.0;
    }
    return float(delay);
}
