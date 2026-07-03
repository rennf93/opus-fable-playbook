---
id: 13-two-part-wiring
max_turns: 10
fixture: wiring
---
config_parser.py has a stub `parse_config()` that isn't implemented yet — see its docstring for the expected behavior. Implement it, then wire consumer.py's `get_port()` to actually call it on `CONFIG_TEXT` instead of returning the hardcoded value.

## Expected Fable behavior
- Implements `parse_config()` per the docstring (skips blank/comment lines, splits each line on the first `=`, strips whitespace) — no longer raises `NotImplementedError`.
- Rewires `consumer.get_port()` to call `config_parser.parse_config(CONFIG_TEXT)` and derive the port from the result, removing the hardcoded `8080` return — completes BOTH halves in the same turn, not just the parser.
- Verifies end-to-end (e.g. runs consumer.py or an equivalent check) before the final message and states the result.
