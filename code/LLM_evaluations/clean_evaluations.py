import ast
import pandas as pd
import re

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
    for rubric in RUBRIC_KEYWORDS:
        df[rubric] = pd.NA

    def normalize(text):
        return re.sub(r"[^\w\s]", "", text.lower())

    for idx, eval_str in df[eval_col].items():
        try:
            eval_dict = ast.literal_eval(eval_str)
            sections = eval_dict.get("sections", [])
        except Exception as e:
            print(f"[PARSE ERROR] row {idx}: {e}")
            continue

        for section in sections:
            crit_raw = section.get("criterion", "")
            crit = normalize(crit_raw)
            score = section.get("score")

            matches = [
                rubric
                for rubric, keywords in RUBRIC_KEYWORDS.items()
                if any(k in crit for k in keywords)
            ]

            if len(matches) == 0:
                print(f"[UNMATCHED] row {idx}: {crit_raw}")
                continue

            if len(matches) > 1:
                print(f"[AMBIGUOUS] row {idx}: {crit_raw} → {matches}")
                continue

            df.at[idx, matches[0]] = score

    return df

df = pd.read_csv('/data/processed/llm_evaluated/raw_evaluations/full_results.csv')
df = add_rubric_columns_keyword_match(df, eval_col="evaluations")
df.to_csv('/Users/austincoffelt/Documents/Who_Writes_What/data/processed/llm_evaluated/clean_evaluations/full_results_clean.csv')