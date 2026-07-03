from stringutils import shout, make_slug


def test_shout():
    assert shout("hi") == "HI!"


def test_make_slug():
    assert make_slug("Hello World") == "hello-world"
