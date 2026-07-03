from legacy import shout, emphasize


def test_shout_still_works():
    assert shout("hi") == "HI!"


def test_emphasize():
    assert emphasize("hi") == "HI!"
