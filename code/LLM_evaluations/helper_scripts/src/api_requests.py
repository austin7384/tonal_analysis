from config import MODEL
from prompt import RUBRIC_OUTPUT_SCHEMA, SYSTEM_PROMPT
import json

def make_messages(rubric_checklist, passage):
    """
    Construct system and user messages for rubric-based evaluation.
    """
    user_payload = {
        "rubric_checklist": rubric_checklist,
        "passage": passage,
    }

    return [
        {"role": "system", "content": SYSTEM_PROMPT},
        {"role": "user", "content": json.dumps(user_payload)},
    ]


def make_single_request(rubric_checklist, passage, custom_id):
    """
    Build a single Responses API request with JSON Schema–enforced output.
    """
    messages = make_messages(rubric_checklist, passage)

    return {
        "custom_id": custom_id,
        "method": "POST",
        "url": "/v1/responses",
        "body": {
            "model": MODEL,
            "input": messages,
            "temperature": 0,
            "text": {
                "format": {
                    "type": "json_schema",
                    "name": "rubric_evaluation",
                    "schema": RUBRIC_OUTPUT_SCHEMA,
                }
            },
        },
    }
