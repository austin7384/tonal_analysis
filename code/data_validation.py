import pandas as pd
import numpy as np

# ───────────────────────────────────────────────────────────────
# LOAD DATA
# ───────────────────────────────────────────────────────────────

df = pd.read_csv('~/tonal_analysis/data/processed/llm_evaluated/clean_evaluations/merged_evaluations.csv')

print("\nLoaded dataset:")
print(f"Rows: {df.shape[0]:,}")
print(f"Columns: {df.shape[1]}")

# ───────────────────────────────────────────────────────────────
# CONFIGURATION — FILL THESE IN IF NEEDED
# ───────────────────────────────────────────────────────────────

ARTICLE_ID_COL = "ArticleID"
AUTHOR_ID_COL = "Author_name"
ABSTRACT_COL = "Abstract"
JOURNAL_COL = "Journal"

TONAL_COLS = [
    'Modal Verb Strength', 'Hedging Frequency & Type', 'Qualifier Density',
    'Acknowledgement of Limitations', 'Caution-Signaling Connectors',
    'Assertiveness & Voice', 'Active/Passive Voice Ratio',
    'Sentence Length & Directness', 'Imperative-Form Occurrence',
    'Pronoun Commitment', 'Novelty-Claim Strength', 'Jargon/Technicality Density',
    'Emotional Valence', 'Evidence & Citation Usage',
    'Practical/Impact Orientation', 'Readability'
]

OVER_HALF_FEMALE_COL = "over_half_female"
SOLO_AUTHORED_COL = "Solo_authored_paper"
SEX_COL = "Sex"

# ───────────────────────────────────────────────────────────────
# 1. DUPLICATE CHECKS
# ───────────────────────────────────────────────────────────────

print("\n── DUPLICATE CHECKS ──")

# Author-Article-Abstract duplicates
if AUTHOR_ID_COL != "":
    author_article_dupes = df.duplicated(subset=[ARTICLE_ID_COL, AUTHOR_ID_COL, ABSTRACT_COL]).sum()
    print(f"Duplicate Author-Article pairs: {author_article_dupes}")
else:
    print("AUTHOR_ID_COL not specified — skipping author-level duplicate check.")

# ───────────────────────────────────────────────────────────────
# 2. MISSINGNESS CHECK
# ───────────────────────────────────────────────────────────────

print("\n── MISSINGNESS CHECK ──")

key_columns = [ARTICLE_ID_COL, ABSTRACT_COL, JOURNAL_COL] + TONAL_COLS + [OVER_HALF_FEMALE_COL]
key_columns = [col for col in key_columns if col in df.columns]

missing_summary = (
    df[key_columns]
    .isna()
    .mean()
    .sort_values(ascending=False)
    .round(4)
)

print("Percent missing (top 15):")
print((missing_summary * 100).head(15))

# ───────────────────────────────────────────────────────────────
# 3. TONAL VARIABLE RANGE CHECK
# ───────────────────────────────────────────────────────────────

print("\n── TONAL RANGE CHECK ──")

for col in TONAL_COLS:
    if col in df.columns:
        min_val = df[col].min()
        max_val = df[col].max()
        print(f"{col}: min={min_val}, max={max_val}")
    else:
        print(f"{col} not found — check column name.")

print("\n⚠ Confirm these ranges match your rubric scale.")

# ───────────────────────────────────────────────────────────────
# 4. LOGICAL CONSISTENCY CHECKS
# ───────────────────────────────────────────────────────────────

print("\n── LOGICAL CONSISTENCY CHECKS ──")

# 4A. Solo-authored consistency
if AUTHOR_ID_COL != "" and SOLO_AUTHORED_COL in df.columns:
    author_counts = df.groupby([ARTICLE_ID_COL, ABSTRACT_COL])[AUTHOR_ID_COL].nunique()
    solo_flag = df.groupby([ARTICLE_ID_COL, ABSTRACT_COL])[SOLO_AUTHORED_COL].first()
    inconsistent_solo = ((author_counts == 1) != solo_flag).sum()
    print(f"Inconsistent solo-authored flags: {inconsistent_solo}")
else:
    print("Skipping solo-authored consistency check.")

# 4B. Over-half-female consistency
if AUTHOR_ID_COL != "" and SEX_COL in df.columns:
    temp = df.copy()
    temp[SEX_COL] = temp[SEX_COL].str.lower().str.strip()
    female_share = (
        temp.assign(is_female=(temp[SEX_COL] == "female"))
            .groupby(ARTICLE_ID_COL)['is_female']
            .mean()
    )
    majority_flag = df.groupby(ARTICLE_ID_COL)[OVER_HALF_FEMALE_COL].first()
    inconsistent_majority = ((female_share >= 0.5) != majority_flag).sum()
    print(f"Inconsistent female-majority flags: {inconsistent_majority}")
else:
    print("Skipping female-majority consistency check.")

# ───────────────────────────────────────────────────────────────
# 5. UNIT OF OBSERVATION CHECK
# ───────────────────────────────────────────────────────────────

print("\n── UNIT OF OBSERVATION CHECK ──")

articles = df[ARTICLE_ID_COL].nunique()
print(f"Unique articles: {articles}")

if AUTHOR_ID_COL != "":
    author_article_rows = df.shape[0]
    print(f"Rows (author-article level): {author_article_rows}")
else:
    print("Dataset appears article-level (AUTHOR_ID_COL not specified).")

# ───────────────────────────────────────────────────────────────
# 6. BASIC DISTRIBUTION SANITY CHECK
# ───────────────────────────────────────────────────────────────

print("\n── BASIC SANITY CHECKS ──")

if JOURNAL_COL in df.columns:
    print("\nArticle counts by journal:")
    print(df.groupby(JOURNAL_COL)[ARTICLE_ID_COL].nunique().head())

if SEX_COL in df.columns:
    print("\nFemale distribution:")
    print(df[SEX_COL].value_counts())

print("\nValidation complete.")
