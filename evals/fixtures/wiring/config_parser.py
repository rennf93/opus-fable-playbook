"""Config parser: turns simple `key=value` text into a dict.

parse_config() is not implemented yet. Expected behavior once it is:
- split on newlines, ignore blank lines and lines starting with '#'
- split each remaining line on the first '=' into key/value, strip
  surrounding whitespace from both
- return a dict[str, str]
"""


def parse_config(raw):
    raise NotImplementedError("parse_config is not implemented yet")
