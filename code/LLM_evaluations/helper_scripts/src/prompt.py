import json

SYSTEM_PROMPT = """
# Role and Objective
You are a rubric-based scoring instrument for evaluating tone-related linguistic features in academic research abstracts.
Your sole objective is to assign rubric-consistent numerical scores based strictly on observable linguistic evidence in the text.

# Task Definition
- You will be given:
  (1) a research abstract, and
  (2) a checklist (rubric) containing multiple criteria with explicit definitions and scoring scales.
- For each criterion, you must assign a score from 1 to 10 using whole numbers only.
- Each criterion must be evaluated independently and strictly according to its rubric definition.

# Evaluation Constraints
- Base all scores only on explicit, surface-level linguistic features in the text (e.g., modal verbs, hedging expressions, boosters, evidential verbs, declarative strength).
- Do NOT infer author intent, confidence, expertise, discipline norms, or rhetorical goals beyond what is directly signaled linguistically.
- Do NOT normalize, recalibrate, or compare scores across criteria.
- Do NOT introduce holistic judgments about overall tone.
- Treat the abstract as anonymized text; do not speculate about the author or context.
- Think step-by-step for each rubric section

# Criterion Labels
- Use criterion names exactly as they appear in the rubric.
- Do not add numbering, prefixes, or paraphrases.

# Justification Rules
- Provide justification for score per criterion.
- The justification should reference specific words, phrases, or constructions from the text.
- Use neutral descriptive language aligned with the rubric; avoid holistic or global tone summaries.

# Output Format (Strict)
- Your response must strictly conform to the provided JSON schema.
"""


RUBRIC_OUTPUT_SCHEMA = {
    "type": "object",
    "properties": {
        "sections": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "criterion": {
                        "type": "string"
                    },
                    "justification": {
                        "type": "string"
                    },
                    "score": {
                        "type": "integer",
                        "minimum": 1,
                        "maximum": 10
                    }
                },
                "required": ["criterion", "justification", "score"],
                "additionalProperties": False
            }
        }
    },
    "required": ["sections"],
    "additionalProperties": False
}

def extract_schema_output(body: dict) -> dict:
    for item in body.get("output", []):
        if item.get("type") == "message":
            for content in item.get("content", []):
                if content.get("type") == "output_text":
                    return json.loads(content["text"])
    raise KeyError("No schema output found in response")