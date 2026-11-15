Fixture for tests/test_config.gd. Broken on purpose:
- config/economy.json is missing
- config/scoring.json has version 2
- word_packs/broken.json is not valid JSON

config/tracker.json is valid, so the expected error count stays at 3.
