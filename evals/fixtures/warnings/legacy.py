"""Legacy formatting helpers. shout() is deprecated in favor of emphasize()."""
import warnings


def shout(text):
    """Deprecated: use emphasize() instead."""
    warnings.warn(
        "shout() is deprecated, use emphasize() instead",
        DeprecationWarning,
        stacklevel=2,
    )
    return text.upper() + "!"


def emphasize(text):
    return text.upper() + "!"
