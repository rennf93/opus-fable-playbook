def parse_xml(raw):
    if raw is None:
        raise ValueError("input is None")
    if not isinstance(raw, str):
        raise ValueError("input must be str")
    if not raw.strip():
        raise ValueError("input is empty")
    return [line.split(",") for line in raw.splitlines()]
