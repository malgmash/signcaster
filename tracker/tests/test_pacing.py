"""Rate limits, the heartbeat and the orphan timeout, with time passed in by hand."""

from signtracker.pacing import Every, OrphanWatch, RateLimiter


def test_rate_limiter_allows_at_most_the_rate() -> None:
    limit = RateLimiter(5)  # one every 0.2 s
    times = [i * 0.05 for i in range(21)]  # 1 second of 20 fps frames (not exact in floating point)
    allowed = [t for t in times if limit.allow(t)]
    assert len(allowed) == 6  # 0.0, 0.2, 0.4, 0.6, 0.8, 1.0
    assert all(b - a >= 0.2 - 1e-9 for a, b in zip(allowed, allowed[1:], strict=False))


def test_thirty_per_second_lets_thirty_fps_through() -> None:
    limit = RateLimiter(30)
    assert sum(limit.allow(i / 30) for i in range(30)) == 30


def test_every_is_due_first_then_once_per_interval() -> None:
    hello = Every(2.0)
    assert hello.due(0.0)
    assert not hello.due(1.9)
    assert hello.due(2.0)
    assert not hello.due(3.0)
    assert hello.due(4.5)


def test_orphan_watch_counts_from_creation() -> None:
    watch = OrphanWatch(5.0, now=100.0)
    assert not watch.orphaned(104.9)
    assert watch.orphaned(105.0)


def test_pings_keep_the_tracker_alive() -> None:
    watch = OrphanWatch(5.0, now=0.0)
    for t in range(1, 20):
        watch.ping(float(t))
        assert not watch.orphaned(t + 0.5)
    assert watch.orphaned(19.0 + 5.0)
