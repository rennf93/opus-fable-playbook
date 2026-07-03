"""Small text helpers."""


def slugify(text):
    return text.strip().lower().replace(" ", "-")
