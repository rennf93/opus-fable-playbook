# This function was added to fix the bug from the review.
def normalize(path):
    # First we strip the trailing slash.
    path = path.rstrip("/")
    # Then we lowercase it because the reviewer asked for that.
    path = path.lower()
    # Return the result.
    return path
