"""
Build the sparse bigram phrase-count matrix for the GST-style phrase-ranking
v1 pipeline (LLM Readability criterion).

Stage 1 (Python): load Hengel analysis sample, take top vs. bottom Readability
quintile, tokenize abstracts to bigrams, apply phrase filters, write three
staging CSVs to data/processed/sg_phrase_analysis/ for the R lasso stage.

Outputs:
  data/processed/sg_phrase_analysis/documents.csv      (N_docs rows)
  data/processed/sg_phrase_analysis/phrases.csv        (V_phrases rows)
  data/processed/sg_phrase_analysis/phrase_counts.csv  (sparse triplets)
"""

import re
from collections import Counter
from pathlib import Path

import pandas as pd

ROOT = Path(__file__).parents[2]

DATA_PATH = ROOT / 'data/processed/llm_evaluated/clean_evaluations/merged_evaluations.csv'
OUT_DIR   = ROOT / 'data/processed/sg_phrase_analysis'
OUT_DIR.mkdir(parents=True, exist_ok=True)

JOURNALS      = {'AER', 'ECA', 'JPE', 'QJE'}
EXCL_PATTERNS = ['corrigendum', 'erratum', ': a correction', ': correction']
SCORE_COL     = 'Readability'
MIN_DOCS      = 5
MIN_TOTAL     = 10

# ── 1. Load and filter to Hengel analysis sample ──────────────────────────────
df = pd.read_csv(DATA_PATH)
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

# ── 2. Quintile binarization on Readability ───────────────────────────────────
p20 = df[SCORE_COL].quantile(0.20)
p80 = df[SCORE_COL].quantile(0.80)
print(f"\nReadability quintile cutoffs: p20={p20}, p80={p80}")

bottom = df[df[SCORE_COL] <= p20].copy()
top    = df[df[SCORE_COL] >= p80].copy()
bottom['group'] = 0
top['group']    = 1
sample = pd.concat([bottom, top], ignore_index=True)
print(f"Bottom-quintile articles (group=0): {len(bottom):,}")
print(f"Top-quintile articles    (group=1): {len(top):,}")
print(f"Quintile-subset total:              {len(sample):,}")

# ── 3. Tokenize abstracts to bigrams ──────────────────────────────────────────
TOKEN_STRIP = re.compile(r"[^a-z0-9'\s]")

def bigrams_for(text: str) -> list[str]:
    text = text.lower()
    text = TOKEN_STRIP.sub(' ', text)
    tokens = [t for t in text.split() if len(t) > 1 and not t.isdigit()]
    return [f"{a}_{b}" for a, b in zip(tokens, tokens[1:])]

doc_bigrams: list[Counter] = []
for abstract in sample['Abstract']:
    doc_bigrams.append(Counter(bigrams_for(abstract)))

# ── 4. Phrase filtering: vocab over the quintile subset ───────────────────────
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

# Sequential phrase index, ordered by descending total_count (stable, helpful for inspection)
phrases_sorted = sorted(surviving, key=lambda p: (-vocab_total[p], p))
phrase_idx = {p: i for i, p in enumerate(phrases_sorted)}

# ── 5. Build sparse triplets and document metadata ────────────────────────────
triplets = []
total_bigrams_per_doc = []
for doc_i, bg in enumerate(doc_bigrams):
    kept = {p: c for p, c in bg.items() if p in phrase_idx}
    total_bigrams_per_doc.append(sum(kept.values()))
    for p, c in kept.items():
        triplets.append((doc_i, phrase_idx[p], c))

documents = pd.DataFrame({
    'doc_idx':       range(len(sample)),
    'ArticleID':     sample['ArticleID'].values,
    'group':         sample['group'].values,
    'Readability':   sample[SCORE_COL].values,
    'total_bigrams': total_bigrams_per_doc,
})

phrases = pd.DataFrame({
    'phrase_idx':  range(len(phrases_sorted)),
    'phrase':      phrases_sorted,
    'n_docs':      [vocab_n_docs[p] for p in phrases_sorted],
    'total_count': [vocab_total[p]  for p in phrases_sorted],
})

phrase_counts = pd.DataFrame(triplets, columns=['doc_idx', 'phrase_idx', 'count'])

# ── 6. Write outputs ──────────────────────────────────────────────────────────
documents_path     = OUT_DIR / 'documents.csv'
phrases_path       = OUT_DIR / 'phrases.csv'
phrase_counts_path = OUT_DIR / 'phrase_counts.csv'

documents.to_csv(documents_path, index=False)
phrases.to_csv(phrases_path, index=False)
phrase_counts.to_csv(phrase_counts_path, index=False)

print(f"\nWrote {documents_path.relative_to(ROOT)}     ({len(documents):,} rows)")
print(f"Wrote {phrases_path.relative_to(ROOT)}       ({len(phrases):,} rows)")
print(f"Wrote {phrase_counts_path.relative_to(ROOT)} ({len(phrase_counts):,} rows)")
