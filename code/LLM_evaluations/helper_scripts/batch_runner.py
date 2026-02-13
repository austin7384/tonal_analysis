import json
import time
import sys
from typing import List, Dict

from src.config import client, logger
from api_requests import make_single_request
from validation import validate_schema
from prompt import extract_schema_output


def batch_call_and_validate(
    passages: List[str],
    custom_ids: List[str],
    rubric_checklist: str,
    batch_file: str = "batch.jsonl",
    poll_interval: int = 60,
) -> List[Dict]:
    """
    Execute a schema-enforced OpenAI batch job over a list of passages.

    This function:
    1. Builds a JSONL batch file (one request per passage)
    2. Uploads and launches the batch
    3. Polls until completion
    4. Retrieves and validates schema-constrained outputs
    5. Returns structured results keyed by custom_id

    Assumptions:
    - Output structure is enforced via response_format=json_schema
    - Each response returns a single JSON object conforming to the schema
    - No free-text parsing or post-hoc structural validation is required

    Args:
        passages (List[str]): Text passages to evaluate.
        custom_ids (List[str]): Unique identifiers for each passage.
        batch_file (str): Path to the temporary JSONL batch file.
        poll_interval (int): Seconds between batch status checks.

    Returns:
        List[Dict]: One result dict per passage containing:
            - id
            - output (schema-validated JSON)
            - validation_passed
            - validation_reason
    """

    # ------------------------------------------------------------------
    # Input sanity checks
    # ------------------------------------------------------------------
    if len(passages) != len(custom_ids):
        raise ValueError("passages and custom_ids must have the same length")

    # ------------------------------------------------------------------
    # Step 1: Build JSONL batch file
    # ------------------------------------------------------------------
    logger.info("Building batch file with %d requests", len(passages))

    with open(batch_file, "w", encoding="utf-8") as f:
        for passage, cid in zip(passages, custom_ids):
            request = make_single_request(rubric_checklist=rubric_checklist, passage=passage, custom_id=cid)
            f.write(json.dumps(request) + "\n")

    # Defensive check: ensure batch file is valid JSONL
    with open(batch_file, "r", encoding="utf-8") as f:
        for line_no, line in enumerate(f, start=1):
            try:
                json.loads(line)
            except json.JSONDecodeError as e:
                logger.error("Invalid JSON on line %d of batch file: %s", line_no, e)
                sys.exit(1)

    logger.info("Batch file validation passed")

    # ------------------------------------------------------------------
    # Step 2: Upload batch and launch execution
    # ------------------------------------------------------------------
    logger.info("Uploading batch file")
    file_obj = client.files.create(
        file=open(batch_file, "rb"),
        purpose="batch"
    )

    batch = client.batches.create(
        input_file_id=file_obj.id,
        endpoint="/v1/responses",
        completion_window="24h"
    )

    logger.info("Batch launched with ID: %s", batch.id)

    # ------------------------------------------------------------------
    # Step 3: Poll batch status
    # ------------------------------------------------------------------
    while True:
        status = client.batches.retrieve(batch.id)
        logger.info("Batch status: %s", status.status)

        if status.status in {"completed", "failed", "expired"}:
            break

        time.sleep(poll_interval)

    if status.status != "completed":
        logger.error("Batch terminated with status: %s", status.status)

        if getattr(status, "errors", None):
            try:
                logger.error(
                    "Batch errors:\n%s",
                    json.dumps(status.errors, indent=2, default=str)
                )
            except Exception:
                logger.error("Could not serialize batch error details")

        raise RuntimeError(f"Batch did not complete successfully: {status.status}")

    # ------------------------------------------------------------------
    # Step 4: Retrieve output file
    # ------------------------------------------------------------------
    if not getattr(status, "output_file_id", None):
        logger.error("Batch completed but produced no output file")

        if getattr(status, "error_file_id", None):
            logger.error("Fetching error file for diagnostics")
            error_file = client.files.content(status.error_file_id)
            for i, line in enumerate(error_file.text.splitlines(), start=1):
                logger.error("Error line %d: %s", i, line)

        raise RuntimeError("Batch completed without output")

    output_file = client.files.content(status.output_file_id)

    # ------------------------------------------------------------------
    # Step 5: Parse and validate schema-constrained outputs
    # ------------------------------------------------------------------
    results = []

    for line in output_file.text.splitlines():
        record = json.loads(line)

        cid = record.get("custom_id")
        response = record.get("response", {})
        body = response.get("body", {})

        try:
            # With schema enforcement, the JSON payload is directly available
            output_json = extract_schema_output(body)

            valid, reason = validate_schema(output_json)

            results.append({
                "id": cid,
                "output": output_json,
                "validation_passed": valid,
                "validation_reason": reason,
            })

            logger.info(
                "Result %s: schema validation %s",
                cid,
                "PASSED" if valid else f"FAILED ({reason})"
            )

        except Exception as e:
            logger.error("Failed to process output for %s: %s", cid, e)
            results.append({
                "id": cid,
                "output": None,
                "validation_passed": False,
                "validation_reason": str(e),
            })

    return results