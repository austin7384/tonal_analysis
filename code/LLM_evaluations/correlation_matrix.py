"""
Compute and export a 16×16 Pearson correlation matrix of LLM tonal criteria.

Output:
  outputs/tables/csv/llm_correlation_matrix.csv  — full 16×16 matrix
  outputs/tables/tex/Table-Corr.tex              — lower-triangle LaTeX table
"""

import pandas as pd
from pathlib import Path

ROOT = Path(__file__).parents[2]

DATA_PATH = ROOT / 'data/processed/llm_evaluated/clean_evaluations/merged_evaluations.csv'
CSV_OUT   = ROOT / 'outputs/tables/csv/llm_correlation_matrix.csv'
TEX_OUT   = ROOT / 'outputs/tables/tex/Table-Corr.tex'

JOURNALS = {'AER', 'ECA', 'JPE', 'QJE'}

LLM_COLS = [
    'Modal Verb Strength',
    'Hedging Frequency & Type',
    'Qualifier Density',
    'Acknowledgement of Limitations',
    'Caution-Signaling Connectors',
    'Assertiveness & Voice',
    'Active/Passive Voice Ratio',
    'Sentence Length & Directness',
    'Imperative-Form Occurrence',
    'Pronoun Commitment',
    'Novelty-Claim Strength',
    'Jargon/Technicality Density',
    'Emotional Valence',
    'Evidence & Citation Usage',
    'Practical/Impact Orientation',
    'Readability',
]

SHORT = {
    'Modal Verb Strength':            'Modal',
    'Hedging Frequency & Type':       'Hedge',
    'Qualifier Density':              'Qual',
    'Acknowledgement of Limitations': 'AckLim',
    'Caution-Signaling Connectors':   'Caution',
    'Assertiveness & Voice':          'Assert',
    'Active/Passive Voice Ratio':     'ActPass',
    'Sentence Length & Directness':   'Direct',
    'Imperative-Form Occurrence':     'Imperat',
    'Pronoun Commitment':             'Pronoun',
    'Novelty-Claim Strength':         'Novelty',
    'Jargon/Technicality Density':    'Jargon',
    'Emotional Valence':              'Emot',
    'Evidence & Citation Usage':      'Evid',
    'Practical/Impact Orientation':   'Pract',
    'Readability':                    'Read',
}

# Errata title patterns excluded from main Stata analysis sample
EXCL_PATTERNS = ['corrigendum', 'erratum', ': a correction', ': correction']

# ── 1. Load & filter ──────────────────────────────────────────────────────────
df = pd.read_csv(DATA_PATH)
df = df[df['Journal'].isin(JOURNALS)]
df = df[df['Language'] == 'English']
mask = df['Title'].str.lower().str.contains('|'.join(EXCL_PATTERNS), na=False)
df = df[~mask]
df = df.drop_duplicates('ArticleID')
data = df[LLM_COLS].apply(pd.to_numeric, errors='coerce').dropna()
N = len(data)
print(f"Article-level observations (main journals, complete LLM data): {N:,}")

# ── 2. Correlation matrix ─────────────────────────────────────────────────────
corr = data.corr()

# ── 3. Save CSV ───────────────────────────────────────────────────────────────
corr.to_csv(CSV_OUT)
print(f"CSV saved: {CSV_OUT.relative_to(ROOT)}")

# ── 4. Build LaTeX ────────────────────────────────────────────────────────────
short_labels = [SHORT[c] for c in LLM_COLS]
n_cols = len(LLM_COLS)

lines = []

lines.append(r'\begin{sidewaystable}[p]')
lines.append(r'\footnotesize')
lines.append(r'\centering')
lines.append(r'\begin{threeparttable}')

# Caption & label
lines.append(
    r'\caption{Pairwise Pearson Correlations among LLM Tonal Criteria}'
)
lines.append(r'\label{tab:llm_corr}')

# Column spec: row-label col + 16 right-aligned cols
col_spec = 'l' + 'r' * n_cols
lines.append(r'\begin{tabular}{' + col_spec + r'}')
lines.append(r'\toprule')

# Header row: rotated short labels
header_cells = [''] + [r'\rotatebox{90}{' + s + '}' for s in short_labels]
lines.append(' & '.join(header_cells) + r' \\')
lines.append(r'\midrule')

# Body: lower triangle (including diagonal)
for i, col_i in enumerate(LLM_COLS):
    row_cells = [short_labels[i]]
    for j, col_j in enumerate(LLM_COLS):
        if j <= i:
            val = corr.loc[col_i, col_j]
            row_cells.append(f'{val:.2f}')
        else:
            row_cells.append('')
    lines.append(' & '.join(row_cells) + r' \\')

lines.append(r'\bottomrule')
lines.append(r'\end{tabular}')

# Table notes
note_text = (
    f'Pearson correlation coefficients computed at the article level '
    f'(N\\,=\\,{N:,}; AER, ECA, JPE, QJE only; one observation per article). '
    r'Criteria scored 1--10. '
    r'Jargon/Technicality Density is shown on its raw scale (not scale-flipped). '
    r'Group membership (G1--G5): '
    r'G1~Creativity \& Hedging: Modal, Hedge, Qual, AckLim, Caution; '
    r'G2~Assertiveness \& Voice: Assert, ActPass; '
    r'G3~Structural Directness: Direct, Imperat; '
    r'G4~Authorial Stance \& Novelty: Pronoun, Novelty, Jargon, Emot; '
    r'G5~Support \& Impact: Evid, Pract. '
    r'Readability is a standalone criterion.'
)
lines.append(r'\begin{tablenotes}')
lines.append(r'\footnotesize')
lines.append(r'\item \textit{Notes}. ' + note_text)
lines.append(r'\end{tablenotes}')

lines.append(r'\end{threeparttable}')
lines.append(r'\end{sidewaystable}')

TEX_OUT.write_text('\n'.join(lines) + '\n')
print(f"LaTeX saved: {TEX_OUT.relative_to(ROOT)}")

# ── 5. Spot checks ────────────────────────────────────────────────────────────
hedge_qual  = corr.loc['Hedging Frequency & Type', 'Qualifier Density']
hedge_assert = corr.loc['Hedging Frequency & Type', 'Assertiveness & Voice']
print(f"Spot check — Hedge vs Qual:   {hedge_qual:+.3f}  (expected positive)")
print(f"Spot check — Hedge vs Assert: {hedge_assert:+.3f}  (expected negative)")
