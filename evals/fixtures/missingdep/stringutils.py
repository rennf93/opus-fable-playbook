"""String helpers used by the test suite.

Depends on helpers.slugify() for slug generation.
"""
from helper import slugify


def shout(text):
    return text.upper() + "!"


def make_slug(text):
    return slugify(text)
