"""Fake tracker: `python -m signtracker.fake --word BLUE --delay 0.6 [--loop]`.

Sends a hello, then one letter message per letter, with no camera at all. Use it to test
the game, in CI, and before the real letter model exists. It keeps the 1 second hello
heartbeat going, so a long word does not look like a disconnect.
"""

from __future__ import annotations

import argparse
import time
from collections.abc import Callable

from signtracker import __version__, protocol

TRACKER_NAME = "fake"
HELLO_SECONDS = 1.0
FAKE_CONFIDENCE = 1.0
FAKE_HOLD_FRAMES = 6

Step = tuple[float, protocol.Message]


def script(word: str, delay: float, start: float = 0.0) -> list[Step]:
    """Every message for one pass over `word`, each with its offset in seconds from the start.

    Letter `t` fields are `start + offset`. Hellos repeat every second between letters.
    """
    steps: list[Step] = [(0.0, protocol.hello(TRACKER_NAME, __version__, 0))]
    last_hello = 0.0
    offset = 0.0
    for value in word.upper():
        if not value.isalpha():
            continue
        offset += delay
        while offset - last_hello >= HELLO_SECONDS:
            last_hello += HELLO_SECONDS
            steps.append((last_hello, protocol.hello(TRACKER_NAME, __version__, 0)))
        steps.append((offset, protocol.letter(start + offset, value, FAKE_CONFIDENCE, FAKE_HOLD_FRAMES)))
    return steps


def play(
    word: str,
    delay: float,
    send: Callable[[protocol.Message], None],
    sleep: Callable[[float], None] = time.sleep,
    clock: Callable[[], float] = time.time,
) -> int:
    """Sends one pass of the script, waiting between steps. Returns how many messages went out."""
    start = clock()
    elapsed = 0.0
    sent = 0
    for offset, msg in script(word, delay, start):
        sleep(max(0.0, offset - elapsed))
        elapsed = offset
        send(msg)
        sent += 1
    return sent


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(prog="python -m signtracker.fake", description=__doc__.splitlines()[0])
    parser.add_argument("--word", required=True, help="letters to send, for example BLUE")
    parser.add_argument("--delay", type=float, default=0.6, help="seconds between letters (default 0.6)")
    parser.add_argument("--loop", action="store_true", help="repeat the word until Ctrl+C")
    parser.add_argument("--game-port", type=int, default=protocol.GAME_PORT)
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    sender = protocol.Sender(args.game_port)
    print(f"Fake tracker: sending {args.word.upper()} to {protocol.HOST}:{args.game_port}")
    try:
        while True:
            play(args.word, args.delay, sender.send)
            if not args.loop:
                break
            time.sleep(args.delay)
    except KeyboardInterrupt:
        pass
    finally:
        sender.close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
