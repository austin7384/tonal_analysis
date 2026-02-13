import pandas as pd

def strip_non_abstract_tail(text) -> str:
    """
    Remove acceptance info and supplemental material from INFORMS abstracts.
    Always returns a string.
    """
    if not isinstance(text, str):
        return ""

    STOP_MARKERS = [
        "This paper was accepted by",
        "Supplemental Material:",
        "Electronic Companion:",
    ]

    for marker in STOP_MARKERS:
        idx = text.find(marker)
        if idx != -1:
            return text[:idx].strip()

    return text.strip()