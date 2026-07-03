"""Loads app config and reports the configured port.

get_port() is a hardcoded stand-in for now — it should call
config_parser.parse_config() on CONFIG_TEXT instead once that exists.
"""

CONFIG_TEXT = """
# app config
host=0.0.0.0
port=8080
debug=false
""".strip()


def get_port():
    return 8080


if __name__ == "__main__":
    print(get_port())
