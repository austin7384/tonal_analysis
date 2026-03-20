"""
Summary statistics for the 16 LLM tonal criteria.

Outputs:
  outputs/tables/csv/llm_summary_overall.csv    — 16 criteria × 7 stats
  outputs/tables/csv/llm_summary_by_gender.csv  — 16 criteria × mean+SD by gender group
  outputs/tables/csv/llm_summary_by_journal.csv — 16 criteria × 4 journals (mean)
  outputs/tables/tex/Table-LLM-Summary.tex      — portrait summary table by gender group
"""

import pandas as pd
from pathlib import Path

ROOT      = Path(__file__).parents[2]
DATA_PATH = ROOT / 'data/processed/llm_evaluated/clean_evaluations/merged_evaluations.csv'
CSV_DIR   = ROOT / 'outputs/tables/csv'
TEX_DIR   = ROOT / 'outputs/tables/tex'

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

GROUPS = [
    ('G1: Creativity \\& Hedging', [
        'Modal Verb Strength', 'Hedging Frequency & Type', 'Qualifier Density',
        'Acknowledgement of Limitations', 'Caution-Signaling Connectors',
    ]),
    ('G2: Assertiveness \\& Voice', [
        'Assertiveness & Voice', 'Active/Passive Voice Ratio',
    ]),
    ('G3: Structural Directness', [
        'Sentence Length & Directness', 'Imperative-Form Occurrence',
    ]),
    ('G4: Authorial Stance \\& Novelty', [
        'Pronoun Commitment', 'Novelty-Claim Strength',
        'Jargon/Technicality Density', 'Emotional Valence',
    ]),
    ('G5: Support \\& Impact', [
        'Evidence & Citation Usage', 'Practical/Impact Orientation',
    ]),
    ('Standalone', [
        'Readability',
    ]),
]

GENDER_CATS = ['All-Male', 'Mixed', 'All-Female']

# Errata title patterns excluded from main Stata analysis sample
EXCL_PATTERNS = ['corrigendum', 'erratum', ': a correction', ': correction']


def fmt(mean, sd):
    if pd.isna(mean) or pd.isna(sd):
        return ''
    return f'{mean:.2f} ({sd:.2f})'


# ── 1. Load & filter ──────────────────────────────────────────────────────────
df_raw = pd.read_csv(DATA_PATH, low_memory=False)
df_raw = df_raw[df_raw['Journal'].isin(JOURNALS)]
df_raw = df_raw[df_raw['Language'] == 'English']
mask = df_raw['Title'].str.lower().str.contains('|'.join(EXCL_PATTERNS), na=False)
df_raw = df_raw[~mask]
print(f"Rows after journal/language/errata filter: {len(df_raw):,}")

art = df_raw.drop_duplicates('ArticleID').copy()
art[LLM_COLS] = art[LLM_COLS].apply(pd.to_numeric, errors='coerce')
print(f"Article-level (deduped):   {len(art):,}")

print("\nJournal counts:")
for j, n in art['Journal'].value_counts().sort_index().items():
    print(f"  {j}: {n:,}")

# ── 2. Gender categories ──────────────────────────────────────────────────────
def gender_cat(ratio):
    if ratio == 0.0:
        return 'All-Male'
    if ratio == 1.0:
        return 'All-Female'
    return 'Mixed'

art['gender_cat'] = art['Female_authorship_ratio'].apply(gender_cat)

print("\nGender category counts (article-level):")
for cat in GENDER_CATS:
    n = (art['gender_cat'] == cat).sum()
    print(f"  {cat}: {n:,}")

# ── 3. CSV 1: overall summary stats ──────────────────────────────────────────
overall = (
    art[LLM_COLS]
    .agg([
        'mean', 'std', 'min',
        lambda x: x.quantile(0.25),
        'median',
        lambda x: x.quantile(0.75),
        'max',
    ])
    .T
)
overall.columns = ['Mean', 'SD', 'Min', 'P25', 'Median', 'P75', 'Max']
overall.index = [SHORT[c] for c in LLM_COLS]
overall = overall.round(3)
overall.to_csv(CSV_DIR / 'llm_summary_overall.csv')
print(f"\nCSV saved: outputs/tables/csv/llm_summary_overall.csv")

# ── 4. CSV 2: by gender ───────────────────────────────────────────────────────
rows = {}
for col in LLM_COLS:
    row = {}
    for grp in GENDER_CATS:
        sub = art.loc[art['gender_cat'] == grp, col].dropna()
        row[f'{grp}_Mean'] = sub.mean()
        row[f'{grp}_SD']   = sub.std()
    full = art[col].dropna()
    row['Full_Mean'] = full.mean()
    row['Full_SD']   = full.std()
    rows[SHORT[col]] = row

by_gender = pd.DataFrame(rows).T.round(3)
by_gender.to_csv(CSV_DIR / 'llm_summary_by_gender.csv')
print(f"CSV saved: outputs/tables/csv/llm_summary_by_gender.csv")

# ── 5. CSV 3: by journal ──────────────────────────────────────────────────────
by_journal = (
    art.groupby('Journal')[LLM_COLS]
    .mean()
    .T
    .round(3)
)
by_journal.index = [SHORT[c] for c in LLM_COLS]
by_journal = by_journal[sorted(JOURNALS)]
by_journal.to_csv(CSV_DIR / 'llm_summary_by_journal.csv')
print(f"CSV saved: outputs/tables/csv/llm_summary_by_journal.csv")

# ── 6. LaTeX table ────────────────────────────────────────────────────────────
N_male   = (art['gender_cat'] == 'All-Male').sum()
N_mixed  = (art['gender_cat'] == 'Mixed').sum()
N_female = (art['gender_cat'] == 'All-Female').sum()
N_all    = len(art)

lines = []
lines.append(r'\begin{table}[H]')
lines.append(r'    \footnotesize')
lines.append(r'    \centering')
lines.append(r'    \begin{threeparttable}')
lines.append(r'        \caption{LLM tonal criteria: summary statistics by gender composition}')
lines.append(r'        \label{tab:llm_summary}')
lines.append(r'        \begin{tabular}{p{3.5cm}cccc}')
lines.append(r'            \toprule')

# Two-line header
lines.append(
    r'            & {All-Male} & {Mixed} & {All-Female} & {Full Sample} \\'
)
lines.append(
    f'            & {{(N\\,=\\,{N_male:,})}} & {{(N\\,=\\,{N_mixed:,})}} '
    f'& {{(N\\,=\\,{N_female:,})}} & {{(N\\,=\\,{N_all:,})}} \\\\'
)
lines.append(r'            \midrule')

# Body: G-group panels
first_group = True
for group_label, cols_in_group in GROUPS:
    if not first_group:
        lines.append(r'            \addlinespace[4pt]')
    first_group = False

    lines.append(
        f'            \\multicolumn{{5}}{{l}}{{\\textit{{{group_label}}}}} \\\\'
    )

    for col in cols_in_group:
        short = SHORT[col]
        cells = []
        for grp in GENDER_CATS:
            sub = art.loc[art['gender_cat'] == grp, col].dropna()
            cells.append(fmt(sub.mean(), sub.std()))
        full = art[col].dropna()
        cells.append(fmt(full.mean(), full.std()))
        lines.append(
            f'            \\quad {short} & ' + ' & '.join(cells) + r' \\'
        )

lines.append(r'            \bottomrule')
lines.append(r'        \end{tabular}')

note = (
    'Means and standard deviations (in parentheses) of LLM-scored tonal criteria, '
    'computed at the article level (AER, ECA, JPE, QJE; one observation per article '
    'after deduplication on ArticleID). '
    'Criteria scored 1--10. '
    'Gender composition is based on \\textit{Female\\_authorship\\_ratio}: '
    'All-Male (ratio\\,=\\,0), Mixed (0\\,<\\,ratio\\,<\\,1), All-Female (ratio\\,=\\,1). '
    'Short labels correspond to G-groups: '
    'G1~Creativity~\\&~Hedging; G2~Assertiveness~\\&~Voice; '
    'G3~Structural~Directness; G4~Authorial~Stance~\\&~Novelty; '
    'G5~Support~\\&~Impact. '
    'Readability is a standalone criterion. '
    'No significance stars shown; this table is descriptive only.'
)
lines.append(r'        \begin{tablenotes}')
lines.append(r'            \footnotesize')
lines.append(r'            \item \textit{Notes}. ' + note)
lines.append(r'        \end{tablenotes}')
lines.append(r'    \end{threeparttable}')
lines.append(r'\end{table}')

(TEX_DIR / 'Table-LLM-Summary.tex').write_text('\n'.join(lines) + '\n')
print(f"LaTeX saved: outputs/tables/tex/Table-LLM-Summary.tex")

# ── 7. Spot checks ────────────────────────────────────────────────────────────
read_full  = art['Readability'].mean()
read_male  = art.loc[art['gender_cat'] == 'All-Male', 'Readability'].mean()
read_fem   = art.loc[art['gender_cat'] == 'All-Female', 'Readability'].mean()
print(f"\nSpot check — Readability (full sample):  {read_full:.3f}")
print(f"Spot check — Readability All-Male:       {read_male:.3f}")
print(f"Spot check — Readability All-Female:     {read_fem:.3f}")
