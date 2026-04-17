"""
Compute Pearson correlations between LLM Readability and the five Hengel
traditional readability measures (Flesch, Flesch-Kincaid, Gunning Fog, SMOG,
Dale-Chall).

Sign convention: all measures negated where needed so higher = easier/clearer.
  Negated: fleschkincaid_score, gunningfog_score, smog_score, dalechall_score
  Not negated: flesch_score (higher raw = easier)

Output:
  outputs/tables/csv/readability_correlation.csv   — 5-row Pearson r table
  outputs/tables/tex/Table-ReadCorr.tex            — LaTeX table
"""

import pandas as pd
from pathlib import Path

ROOT = Path(__file__).parents[2]

LLM_PATH  = ROOT / 'data/processed/llm_evaluated/clean_evaluations/merged_evaluations.csv'
READ_PATH = ROOT / 'data/raw/hengel_replication_data/ReadStat.csv'
CSV_OUT   = ROOT / 'outputs/tables/csv/readability_correlation.csv'
TEX_OUT   = ROOT / 'outputs/tables/tex/Table-ReadCorr.tex'

JOURNALS      = {'AER', 'ECA', 'JPE', 'QJE'}
EXCL_PATTERNS = ['corrigendum', 'erratum', ': a correction', ': correction']

HENGEL_COLS = [
    'flesch_score',
    'fleschkincaid_score',
    'gunningfog_score',
    'smog_score',
    'dalechall_score',
]

NEGATE = {'fleschkincaid_score', 'gunningfog_score', 'smog_score', 'dalechall_score'}

DISPLAY = {
    'flesch_score':          'Flesch Reading Ease',
    'fleschkincaid_score':   'Flesch-Kincaid Grade Level (negated)',
    'gunningfog_score':      'Gunning Fog Index (negated)',
    'smog_score':            'SMOG Index (negated)',
    'dalechall_score':       'Dale-Chall Score (negated)',
}

# ── 1. Load & filter LLM evaluations ─────────────────────────────────────────
llm = pd.read_csv(LLM_PATH)
llm = llm[llm['Journal'].isin(JOURNALS)]
llm = llm[llm['Language'] == 'English']
mask = llm['Title'].str.lower().str.contains('|'.join(EXCL_PATTERNS), na=False)
llm = llm[~mask]
llm = llm.drop_duplicates('ArticleID')
llm = llm[['ArticleID', 'Readability']]
llm['Readability'] = pd.to_numeric(llm['Readability'], errors='coerce')

# ── 2. Load & pivot Hengel ReadStat ──────────────────────────────────────────
read_stat = pd.read_csv(READ_PATH)
wide = read_stat.pivot_table(index='ArticleID', columns='StatName', values='StatValue')
wide = wide[HENGEL_COLS].copy()

for col in NEGATE:
    wide[col] = -wide[col]

# ── 3. Merge & correlate ──────────────────────────────────────────────────────
df = llm.merge(wide.reset_index(), on='ArticleID')
df = df[['Readability'] + HENGEL_COLS].dropna()
N = len(df)
print(f"Matched observations (Hengel + LLM, main journals): {N:,}")

corr_row = df.corr()['Readability'].drop('Readability')

# ── 4. Save CSV ───────────────────────────────────────────────────────────────
result = pd.DataFrame({
    'Measure': [DISPLAY[c] for c in HENGEL_COLS],
    'Pearson_r': [corr_row[c] for c in HENGEL_COLS],
})
result.to_csv(CSV_OUT, index=False)
print(f"CSV saved: {CSV_OUT.relative_to(ROOT)}")

for _, row in result.iterrows():
    print(f"  {row['Measure']:<45}  r = {row['Pearson_r']:+.3f}")

# ── 5. Build LaTeX ────────────────────────────────────────────────────────────
lines = []
lines.append(r'\begin{table}[htbp]')
lines.append(r'\centering')
lines.append(r'\begin{threeparttable}')
lines.append(r'\caption{Correlations between LLM Readability and Traditional Readability Measures}')
lines.append(r'\label{tab:readability_corr}')
lines.append(r'\begin{tabular}{lr}')
lines.append(r'\toprule')
lines.append(r'Readability Measure & Pearson $r$ \\')
lines.append(r'\midrule')
for col in HENGEL_COLS:
    lines.append(f'{DISPLAY[col]} & {corr_row[col]:.3f} \\\\')
lines.append(r'\bottomrule')
lines.append(r'\end{tabular}')

note_text = (
    f'Pearson correlation coefficients between the LLM Readability score (1--10; '
    f'10\\,=\\,easiest to understand) and five traditional readability measures '
    f'(N\\,=\\,{N:,}; AER, ECA, JPE, QJE; English-language articles only; '
    f'one observation per article). '
    r'Hengel measures are sign-flipped where needed so that higher values indicate '
    r'easier/clearer writing: Flesch-Kincaid Grade Level, Gunning Fog Index, SMOG '
    r'Index, and Dale-Chall Score are negated; Flesch Reading Ease is not.'
)
lines.append(r'\begin{tablenotes}')
lines.append(r'\footnotesize')
lines.append(r'\item \textit{Notes}. ' + note_text)
lines.append(r'\end{tablenotes}')
lines.append(r'\end{threeparttable}')
lines.append(r'\end{table}')

TEX_OUT.write_text('\n'.join(lines) + '\n')
print(f"LaTeX saved: {TEX_OUT.relative_to(ROOT)}")
