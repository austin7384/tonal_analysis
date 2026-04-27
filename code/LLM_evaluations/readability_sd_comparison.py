"""
Compare regression coefficients on female ratio across readability measures
in standard deviation units (beta / SD(Y)).

Coefficients are hard-coded from slide 8 (Table-10 / Table-10-llm Stata output).
SDs are computed from the matched regression sample (Hengel + LLM inner join).
"""

import pandas as pd
from pathlib import Path

ROOT = Path(__file__).parents[2]

LLM_PATH  = ROOT / 'data/processed/llm_evaluated/clean_evaluations/Hengel_evaluations.csv'
READ_PATH = ROOT / 'data/raw/hengel_replication_data/ReadStat.csv'

JOURNALS      = {'AER', 'ECA', 'JPE', 'QJE'}
EXCL_PATTERNS = ['corrigendum', 'erratum', ': a correction', ': correction']

HENGEL_COLS = [
    'flesch_score',
    'fleschkincaid_score',
    'gunningfog_score',
    'smog_score',
    'dalechall_score',
]

# Raw OLS coefficients on FemRatio from slide 8
COEFFICIENTS = {
    'flesch_score':        {'label': 'Flesch Reading Ease',        'col4': 1.26, 'col5': 1.49},
    'fleschkincaid_score': {'label': 'Flesch-Kincaid Grade Level', 'col4': 0.24, 'col5': 0.26},
    'gunningfog_score':    {'label': 'Gunning Fog Index',          'col4': 0.40, 'col5': 0.42},
    'smog_score':          {'label': 'SMOG Index',                 'col4': 0.27, 'col5': 0.29},
    'dalechall_score':     {'label': 'Dale-Chall Score',           'col4': 0.08, 'col5': 0.09},
    'Readability':         {'label': 'LLM Readability',            'col4': 0.40, 'col5': 0.32},
}

# ── 1. Load & filter LLM evaluations ─────────────────────────────────────────
llm = pd.read_csv(LLM_PATH)
llm = llm[llm['Journal'].isin(JOURNALS)]
llm = llm[llm['Language'] == 'English']
title_col = 'Title' if 'Title' in llm.columns else 'Title_PBLSH'
mask = llm[title_col].str.lower().str.contains('|'.join(EXCL_PATTERNS), na=False)
llm = llm[~mask]
llm = llm.drop_duplicates('ArticleID')
llm = llm[['ArticleID', 'Readability']]
llm['Readability'] = pd.to_numeric(llm['Readability'], errors='coerce')

# ── 2. Load & pivot Hengel ReadStat ──────────────────────────────────────────
read_stat = pd.read_csv(READ_PATH)
wide = read_stat.pivot_table(index='ArticleID', columns='StatName', values='StatValue')
wide = wide[HENGEL_COLS].reset_index()

# ── 3. Merge on matched sample ────────────────────────────────────────────────
df = llm.merge(wide, on='ArticleID').dropna(subset=['Readability'] + HENGEL_COLS)
N  = len(df)
print(f"Matched sample N = {N:,}\n")

# ── 4. Compute SDs and beta/SD ────────────────────────────────────────────────
rows = []
for col, info in COEFFICIENTS.items():
    sd = df[col].std()
    rows.append({
        'Measure':      info['label'],
        'SD':           sd,
        'Col4_beta':    info['col4'],
        'Col5_beta':    info['col5'],
        'Col4_beta_sd': info['col4'] / sd,
        'Col5_beta_sd': info['col5'] / sd,
    })

results = pd.DataFrame(rows)

# ── 5. Print table ────────────────────────────────────────────────────────────
hdr = f"{'Measure':<35} {'SD':>6}  {'Col(4) β':>9}  {'β/SD':>6}  {'Col(5) β':>9}  {'β/SD':>6}"
print(hdr)
print('-' * len(hdr))
for _, r in results.iterrows():
    sep = '  ─' if r['Measure'] == 'LLM Readability' else ''
    print(f"{r['Measure']:<35} {r['SD']:>6.3f}  {r['Col4_beta']:>9.2f}  {r['Col4_beta_sd']:>6.3f}  "
          f"{r['Col5_beta']:>9.2f}  {r['Col5_beta_sd']:>6.3f}{sep}")
