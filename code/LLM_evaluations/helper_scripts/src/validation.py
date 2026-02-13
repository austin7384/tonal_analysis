def validate_schema(output):
    if not isinstance(output, dict):
        return False, "Output is not an object"

    if "sections" not in output:
        return False, "Missing 'sections' key"

    if not isinstance(output["sections"], list):
        return False, "'sections' is not a list"

    return True, "OK"

