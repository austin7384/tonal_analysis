import re
from typing import Optional, Dict

def parse_acceptance_info(text: Optional[str]) -> Dict[str, Optional[str]]:
    """
    Parse acceptance information into editor name and department.

    Expected format:
        "This paper was accepted by NAME, DEPARTMENT."
    """

    if not text:
        return {"editor": None, "department": None}

    pattern = re.compile(
        r"accepted by\s+(?P<editor>[^,]+),\s*(?P<department>[^.]+)",
        flags=re.IGNORECASE
    )

    match = pattern.search(text)

    if not match:
        return {"editor": None, "department": None}

    return {
        "editor": match.group("editor").strip(),
        "department": match.group("department").strip(),
    }