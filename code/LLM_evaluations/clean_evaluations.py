import ast
import re
import pandas as pd

RUBRIC_KEYWORDS = {
    "Modal Verb Strength": ["modal"],
    "Hedging Frequency & Type": ["hedging"],
    "Qualifier Density": ["qualifier"],
    "Acknowledgement of Limitations": ["limitation"],
    "Caution-Signaling Connectors": ["caution", "contrast"],
    "Assertiveness & Voice": ["assertive"],
    "Active/Passive Voice Ratio": ["active", "passive"],
    "Sentence Length & Directness": ["sentence", "direct"],
    "Imperative-Form Occurrence": ["imperative"],
    "Pronoun Commitment": ["pronoun"],
    "Novelty-Claim Strength": ["novelty", "original"],
    "Jargon/Technicality Density": ["jargon", "technical"],
    "Emotional Valence": ["emotional", "emotion"],
    "Evidence & Citation Usage": ["citation", "evidence"],
    "Practical/Impact Orientation": ["practical", "managerial"],
    "Readability": ["readability", "readable"],
}


def add_rubric_columns_keyword_match(df: pd.DataFrame, eval_col: str) -> pd.DataFrame:
    """
    Parses a column of LLM evaluation strings and extracts rubric scores into
    separate columns. Supports two formats:
      - Wrapped:  {'sections': [{criterion, score, ...}, ...]}
      - Flat list: [{criterion, score, ...}, ...]
    """
    # Initialize all rubric columns with NA
    for rubric in RUBRIC_KEYWORDS:
        df[rubric] = pd.NA

    def normalize(text: str) -> str:
        """Lowercase and strip punctuation for robust keyword matching."""
        return re.sub(r"[^\w\s]", "", text.lower())

    for idx, eval_str in df[eval_col].items():
        # --- Parse the evaluation string ---
        try:
            parsed = ast.literal_eval(eval_str)

            # Handle both formats: wrapped dict or flat list
            if isinstance(parsed, dict):
                sections = parsed.get("sections", [])
            elif isinstance(parsed, list):
                sections = parsed
            else:
                print(f"[UNKNOWN FORMAT] row {idx}: {type(parsed)}")
                continue

        except Exception as e:
            print(f"[PARSE ERROR] row {idx}: {e}")
            continue

        # --- Match each section to a rubric criterion ---
        for section in sections:
            crit_raw = section.get("criterion", "")
            crit_name = crit_raw.split(":")[0]
            crit = normalize(crit_name)
            score = section.get("score")

            matches = [
                rubric
                for rubric, keywords in RUBRIC_KEYWORDS.items()
                if any(k in crit for k in keywords)
            ]

            if len(matches) == 0:
                print(f"[UNMATCHED] row {idx}: '{crit_raw}'")
                continue

            if len(matches) > 1:
                print(f"[AMBIGUOUS] row {idx}: '{crit_raw}' → {matches}")
                continue

            df.at[idx, matches[0]] = score

    return df


# --- Load, process, and save ---
df = pd.read_csv('~/Documents/Who_Writes_What/data/processed/llm_evaluated/raw_evaluations/Hengel_evaluations.csv')
df.dropna(subset='evaluation_nber_parsed', inplace=True)
df.drop_duplicates(subset=['NberID', 'evaluation_nber_parsed'], inplace=True)
df = add_rubric_columns_keyword_match(df, eval_col="evaluation_nber_parsed")
df.to_csv('~/Documents/Who_Writes_What/data/processed/llm_evaluated/clean_evaluations/Hengel_nber_evaluations.csv')