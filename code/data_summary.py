import pandas as pd
import numpy as np
from pathlib import Path

df = pd.read_csv('~/tonal_analysis/data/processed/llm_evaluated/clean_evaluations/merged_evaluations.csv')
df.drop(columns=["Unnamed: 0"], inplace=True)

# ── Setup ────────────────────────────────────────────────────────────────────
TONAL_COLS = [
    'Modal Verb Strength', 'Hedging Frequency & Type', 'Qualifier Density',
    'Acknowledgement of Limitations', 'Caution-Signaling Connectors',
    'Assertiveness & Voice', 'Active/Passive Voice Ratio',
    'Sentence Length & Directness', 'Imperative-Form Occurrence',
    'Pronoun Commitment', 'Novelty-Claim Strength', 'Jargon/Technicality Density',
    'Emotional Valence', 'Evidence & Citation Usage',
    'Practical/Impact Orientation', 'Readability'
]

OUTPUT_DIR = Path('~/tonal_analysis/outputs/tables/').expanduser()
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

def save(df, filename):
    path = OUTPUT_DIR / filename
    df.to_csv(path)
    print(f"  Saved → {path}")

# ── 1. Article-level tonal feature summary ───────────────────────────────────
article_tonal = df.groupby('ArticleID')[TONAL_COLS].mean()
summary = article_tonal.agg(['mean', 'std']).T
summary.columns = ['Mean', 'Std Dev']
summary = summary.round(3)
save(summary, 'table1_tonal_summary.csv')

# ── 2. Article count by journal ──────────────────────────────────────────────
journal_counts = (df.groupby('Journal')['Title']
                    .nunique()
                    .reset_index()
                    .rename(columns={'Title': 'Article Count'})
                    .sort_values('Article Count', ascending=False))
save(journal_counts, 'table2_articles_by_journal.csv')

# ── 3. Author-level sex counts ───────────────────────────────────────────────
df['Sex'] = df['Sex'].str.lower().str.strip()
sex_counts = df['Sex'].value_counts().reset_index()
sex_counts.columns = ['Sex', 'Count']
sex_counts['Pct'] = (sex_counts['Count'] / sex_counts['Count'].sum() * 100).round(1)
save(sex_counts, 'table3_author_sex_counts.csv')

# ── 4. Articles: >50% female vs ≤50% female authorship ──────────────────────
art_female = (df.groupby('ArticleID')['over_half_female']
                .first()
                .reset_index())
female_split = art_female['over_half_female'].value_counts().reset_index()
female_split.columns = ['Over Half Female', 'Article Count']
female_split['Pct'] = (female_split['Article Count'] / female_split['Article Count'].sum() * 100).round(1)
save(female_split, 'table4_female_majority_articles.csv')

# ── 5. Article count by department ──────────────────────────────────────────
dept_counts = (df.groupby('Department')['Title']
                 .nunique()
                 .reset_index()
                 .rename(columns={'Title': 'Article Count'})
                 .sort_values('Article Count', ascending=False))
save(dept_counts, 'table5_articles_by_department.csv')

# ── 6. Tonal features by female authorship majority (article level) ──────────
art_tonal = df.groupby('ArticleID')[TONAL_COLS + ['over_half_female']].mean()
majority_tonal = art_tonal.groupby('over_half_female')[TONAL_COLS].mean().T.round(3)
majority_tonal.index.name = 'Feature'
save(majority_tonal, 'table6_tonal_by_female_majority.csv')

# ── 7. Solo vs. co-authored counts & tonal comparison ───────────────────────
art_solo = df.groupby('ArticleID')['Solo_authored_paper'].first().reset_index()
solo_counts = art_solo['Solo_authored_paper'].value_counts().reset_index()
solo_counts.columns = ['Solo Authored', 'Article Count']
save(solo_counts, 'table7a_solo_vs_coauthored_counts.csv')

art_tonal2 = df.groupby('ArticleID')[TONAL_COLS + ['Solo_authored_paper']].mean()
solo_tonal = art_tonal2.groupby('Solo_authored_paper')[TONAL_COLS].mean().T.round(3)
solo_tonal.columns = ['Co-authored', 'Solo']
solo_tonal.index.name = 'Feature'
save(solo_tonal, 'table7b_tonal_solo_vs_coauthored.csv')

# ── 8. Mean tonal features by journal ───────────────────────────────────────
journal_tonal = (df.groupby(['ArticleID'] + ['Journal'])[TONAL_COLS]
                   .mean()
                   .reset_index()
                   .groupby('Journal')[TONAL_COLS]
                   .mean()
                   .round(3))
save(journal_tonal, 'table8_tonal_by_journal.csv')

# ── 9. Language × Sex crosstab ──────────────────────────────────────────────
lang_sex = pd.crosstab(df['Native_language'], df['Sex'], margins=True)
save(lang_sex, 'table9_language_by_sex.csv')

print("\nAll tables saved.")