"""
Build the sparse bigram phrase-count matrix for the GST-style phrase-ranking
v2 pipeline (LLM Readability criterion, residualized on col. (5) controls).

Stage 1 (Python): load the Hengel analysis sample, merge in col. (5) controls
from article_primary_jel.dta, residualize Readability via OLS, take top vs.
bottom quintile of the *residual*, tokenize abstracts to bigrams, apply phrase
filters, write three staging CSVs to
data/processed/sg_phrase_analysis_residualized/ for the R lasso stage.

Col. (5) controls (from Table-5-llm.do:33, slide 8/10 col 5):
  Journal x Year FE, Editor FE, MaxInst FE, NativeEnglish, JEL1_*, Type_*,
  Blind, N, Maxt, MaxT, asinhCiteCount.

Gender measures and nber_score are intentionally excluded (gender is a
treatment in the main paper; nber_score is the draft-readability control,
which would change the residualization's interpretation).

Outputs:
  data/processed/sg_phrase_analysis_residualized/documents.csv      (N_docs rows)
  data/processed/sg_phrase_analysis_residualized/phrases.csv        (V_phrases rows)
  data/processed/sg_phrase_analysis_residualized/phrase_counts.csv  (sparse triplets)
"""

import re
import warnings
from collections import Counter
from pathlib import Path

import numpy as np
import pandas as pd
import statsmodels.api as sm

ROOT = Path(__file__).parents[2]

DATA_PATH     = ROOT / 'data/processed/llm_evaluated/clean_evaluations/merged_evaluations.csv'
CONTROLS_PATH = ROOT / 'data/raw/hengel_generated/article_primary_jel.dta'
OUT_DIR       = ROOT / 'data/processed/sg_phrase_analysis_residualized'
OUT_DIR.mkdir(parents=True, exist_ok=True)

JOURNALS      = {'AER', 'ECA', 'JPE', 'QJE'}
EXCL_PATTERNS = ['corrigendum', 'erratum', ': a correction', ': correction']
SCORE_COL     = 'Readability'
MIN_DOCS      = 5
MIN_TOTAL     = 10

CONTINUOUS_CTRLS = ['N', 'Maxt', 'MaxT', 'asinhCiteCount']
CATEGORICAL_CTRLS = ['Editor', 'MaxInst', 'NativeEnglish', 'Blind']
DUMMY_PREFIXES = ['JEL1_', 'Type_']

# ── 1. Load and filter to Hengel analysis sample ──────────────────────────────
df = pd.read_csv(DATA_PATH, low_memory=False)
print(f"Raw rows (author-level):                       {len(df):,}")

df = df[df['Journal'].isin(JOURNALS)]
print(f"After main-journal filter (AER/ECA/JPE/QJE):    {len(df):,}")

df = df[df['Language'] == 'English']
print(f"After English filter:                           {len(df):,}")

mask = df['Title'].str.lower().str.contains('|'.join(EXCL_PATTERNS), na=False)
df = df[~mask]
print(f"After errata-title filter:                      {len(df):,}")

df = df.drop_duplicates('ArticleID')
print(f"After dedupe to article-level:                  {len(df):,}")

df = df.dropna(subset=['Abstract', SCORE_COL])
df[SCORE_COL] = pd.to_numeric(df[SCORE_COL], errors='coerce')
df = df.dropna(subset=[SCORE_COL])
print(f"After dropping missing Abstract/{SCORE_COL}:     {len(df):,}")

# ── 2. Merge col. (5) controls ────────────────────────────────────────────────
ctrls = pd.read_stata(CONTROLS_PATH, convert_categoricals=False)

jel_cols  = sorted(c for c in ctrls.columns if c.startswith('JEL1_'))
type_cols = sorted(c for c in ctrls.columns if c.startswith('Type_'))
needed = (['ArticleID', 'Year'] + CONTINUOUS_CTRLS + CATEGORICAL_CTRLS
          + jel_cols + type_cols)
missing = [c for c in needed if c not in ctrls.columns]
if missing:
    raise SystemExit(f"Missing controls in {CONTROLS_PATH}: {missing}")

print(f"\nControls table:    {len(ctrls):,} articles, "
      f"{len(jel_cols)} JEL1_*, {len(type_cols)} Type_*")

df = df.merge(ctrls[needed], on='ArticleID', how='inner', validate='1:1')
print(f"After inner-merge w/ col-5 controls:            {len(df):,}")

df = df.dropna(subset=CONTINUOUS_CTRLS + CATEGORICAL_CTRLS + ['Year'])
print(f"After dropping rows w/ missing controls:        {len(df):,}")

# ── 3. Residualize Readability on col. (5) controls ───────────────────────────
# Build design matrix manually: dummies for Year x Journal, Editor, MaxInst,
# NativeEnglish, Blind; pass JEL1_*/Type_* through as-is; continuous controls
# as floats. drop_first=True on each categorical block to avoid the trivial
# constant-collinearity. OLS w/ pinv tolerates remaining rank deficiency
# (e.g. unbalanced Year x Journal cells); residuals are invariant to it.
yj = df[['Year', 'Journal']].astype(str).agg('_'.join, axis=1)
X_parts = [
    pd.get_dummies(yj,                    prefix='YJ', drop_first=True, dtype=float),
    pd.get_dummies(df['Editor'],          prefix='Ed', drop_first=True, dtype=float),
    pd.get_dummies(df['MaxInst'],         prefix='In', drop_first=True, dtype=float),
    pd.get_dummies(df['NativeEnglish'],   prefix='NE', drop_first=True, dtype=float),
    pd.get_dummies(df['Blind'],           prefix='Bl', drop_first=True, dtype=float),
    df[CONTINUOUS_CTRLS].astype(float).reset_index(drop=True),
    df[jel_cols].drop(columns=[jel_cols[-1]]).astype(float).reset_index(drop=True),
    df[type_cols].drop(columns=[type_cols[-1]]).astype(float).reset_index(drop=True),
]
# Align all blocks on a fresh integer index so concat lines up cleanly.
X_parts = [p.reset_index(drop=True) for p in X_parts]
X = pd.concat(X_parts, axis=1)
X = sm.add_constant(X, has_constant='add')
y = df[SCORE_COL].astype(float).reset_index(drop=True)

with warnings.catch_warnings():
    warnings.simplefilter('ignore')
    ols = sm.OLS(y, X).fit()

print(f"\nOLS design:        {X.shape[0]} obs x {X.shape[1]} columns")
print(f"OLS R^2:           {ols.rsquared:.4f}")
print(f"OLS R^2 adj:       {ols.rsquared_adj:.4f}")
print(f"Residual std:      {ols.resid.std():.4f} (raw Readability std: {y.std():.4f})")

df = df.reset_index(drop=True)
df['Readability_resid'] = ols.resid.values

# ── 4. Quintile binarization on the residual ──────────────────────────────────
p20 = df['Readability_resid'].quantile(0.20)
p80 = df['Readability_resid'].quantile(0.80)
print(f"\nResidual quintile cutoffs: p20={p20:.4f}, p80={p80:.4f}")

bottom = df[df['Readability_resid'] <= p20].copy()
top    = df[df['Readability_resid'] >= p80].copy()
bottom['group'] = 0
top['group']    = 1
sample = pd.concat([bottom, top], ignore_index=True)
print(f"Bottom-quintile articles (group=0): {len(bottom):,}")
print(f"Top-quintile articles    (group=1): {len(top):,}")
print(f"Quintile-subset total:              {len(sample):,}")

# ── 5. Tokenize abstracts to bigrams ──────────────────────────────────────────
TOKEN_STRIP = re.compile(r"[^a-z0-9'\s]")

def bigrams_for(text: str) -> list[str]:
    text = text.lower()
    text = TOKEN_STRIP.sub(' ', text)
    tokens = [t for t in text.split() if len(t) > 1 and not t.isdigit()]
    return [f"{a}_{b}" for a, b in zip(tokens, tokens[1:])]

doc_bigrams: list[Counter] = []
for abstract in sample['Abstract']:
    doc_bigrams.append(Counter(bigrams_for(abstract)))

# ── 6. Phrase filtering: vocab over the quintile subset ───────────────────────
vocab_n_docs = Counter()
vocab_total  = Counter()
for bg in doc_bigrams:
    vocab_total.update(bg)
    for phrase in bg:
        vocab_n_docs[phrase] += 1

surviving = {
    p for p in vocab_total
    if vocab_n_docs[p] >= MIN_DOCS and vocab_total[p] >= MIN_TOTAL
}
print(f"\nUnique bigrams (pre-filter):  {len(vocab_total):,}")
print(f"Surviving phrases (n_docs>={MIN_DOCS} & total>={MIN_TOTAL}): {len(surviving):,}")

phrases_sorted = sorted(surviving, key=lambda p: (-vocab_total[p], p))
phrase_idx = {p: i for i, p in enumerate(phrases_sorted)}

# ── 7. Build sparse triplets and document metadata ────────────────────────────
triplets = []
total_bigrams_per_doc = []
for doc_i, bg in enumerate(doc_bigrams):
    kept = {p: c for p, c in bg.items() if p in phrase_idx}
    total_bigrams_per_doc.append(sum(kept.values()))
    for p, c in kept.items():
        triplets.append((doc_i, phrase_idx[p], c))

documents = pd.DataFrame({
    'doc_idx':            range(len(sample)),
    'ArticleID':          sample['ArticleID'].values,
    'group':              sample['group'].values,
    'Readability':        sample[SCORE_COL].values,
    'Readability_resid':  sample['Readability_resid'].values,
    'total_bigrams':      total_bigrams_per_doc,
})

phrases = pd.DataFrame({
    'phrase_idx':  range(len(phrases_sorted)),
    'phrase':      phrases_sorted,
    'n_docs':      [vocab_n_docs[p] for p in phrases_sorted],
    'total_count': [vocab_total[p]  for p in phrases_sorted],
})

phrase_counts = pd.DataFrame(triplets, columns=['doc_idx', 'phrase_idx', 'count'])

# ── 8. Write outputs ──────────────────────────────────────────────────────────
documents_path     = OUT_DIR / 'documents.csv'
phrases_path       = OUT_DIR / 'phrases.csv'
phrase_counts_path = OUT_DIR / 'phrase_counts.csv'

documents.to_csv(documents_path, index=False)
phrases.to_csv(phrases_path, index=False)
phrase_counts.to_csv(phrase_counts_path, index=False)

print(f"\nWrote {documents_path.relative_to(ROOT)}     ({len(documents):,} rows)")
print(f"Wrote {phrases_path.relative_to(ROOT)}       ({len(phrases):,} rows)")
print(f"Wrote {phrase_counts_path.relative_to(ROOT)} ({len(phrase_counts):,} rows)")
