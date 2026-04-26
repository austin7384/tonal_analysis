"""
Figure 2: Female − Male differences in means with 95% CI across 16 LLM criteria.

Styling matches the Stata publishing-female scheme (pfblue bars, no grid, gray axes).
Font sizes enlarged for slide use.

Output: outputs/figures/diff_means_plot_slides.pdf
"""

import numpy as np
import pandas as pd
import matplotlib
import matplotlib.pyplot as plt
import matplotlib.ticker as mticker
from pathlib import Path
try:
    from scipy import stats as _scipy_stats
    def _ttest(a, b):
        return _scipy_stats.ttest_ind(a, b, equal_var=False).pvalue
except ImportError:
    def _ttest(a, b):
        # Welch's t-test p-value approximation without scipy
        n1, n2 = len(a), len(b)
        v1, v2 = np.var(a, ddof=1), np.var(b, ddof=1)
        se = np.sqrt(v1/n1 + v2/n2)
        t = (np.mean(a) - np.mean(b)) / se
        df = (v1/n1 + v2/n2)**2 / ((v1/n1)**2/(n1-1) + (v2/n2)**2/(n2-1))
        import math
        # Two-sided p-value using normal approximation for large df
        return 2 * (1 - 0.5*(1 + math.erf(abs(t)/math.sqrt(2))))

matplotlib.rcParams['font.family'] = 'sans-serif'
matplotlib.rcParams['font.sans-serif'] = ['Avenir', 'Helvetica Neue', 'Helvetica',
                                           'Arial', 'DejaVu Sans']

ROOT      = Path(__file__).parents[2]
DATA_PATH = ROOT / 'data/processed/llm_evaluated/clean_evaluations/merged_evaluations.csv'
OUT_PATH  = ROOT / 'outputs/figures/diff_means_plot_slides.pdf'

# ── publishing-female scheme colours ─────────────────────────────────────────
PF_BLUE   = '#346C8B'
PF_PINK   = '#D85C63'
AXIS_GRAY = '#747474'
GRID_GRAY = '#B0C5CC'

# ── 16 LLM criteria (column names in merged_evaluations.csv) ─────────────────
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

# Display labels for the x-axis — single words, slide-friendly
DISPLAY = {
    'Modal Verb Strength':            'Modal Verb',
    'Hedging Frequency & Type':       'Hedging',
    'Qualifier Density':              'Qualifiers',
    'Acknowledgement of Limitations': 'Limitations',
    'Caution-Signaling Connectors':   'Caution',
    'Assertiveness & Voice':          'Assertiveness',
    'Active/Passive Voice Ratio':     'Active Voice',
    'Sentence Length & Directness':   'Directness',
    'Imperative-Form Occurrence':     'Imperatives',
    'Pronoun Commitment':             'Pronouns',
    'Novelty-Claim Strength':         'Novelty',
    'Jargon/Technicality Density':    'Jargon',
    'Emotional Valence':              'Emotional',
    'Evidence & Citation Usage':      'Evidence',
    'Practical/Impact Orientation':   'Practical',
    'Readability':                    'Readability',
}

EXCL_PATTERNS = ['corrigendum', 'erratum', ': a correction', ': correction']
JOURNALS      = {'AER', 'ECA', 'JPE', 'QJE'}

# ── 1. Load & filter ──────────────────────────────────────────────────────────
df = pd.read_csv(DATA_PATH, low_memory=False)
df = df[df['Journal'].isin(JOURNALS)]
df = df[df['Language'] == 'English']
mask = df['Title'].str.lower().str.contains('|'.join(EXCL_PATTERNS), na=False)
df = df[~mask]
df = df.drop_duplicates('ArticleID').copy()
df[LLM_COLS] = df[LLM_COLS].apply(pd.to_numeric, errors='coerce')
print(f"N = {len(df):,} articles")

# ── 2. Flip jargon sign (higher = less jargon, consistent with other criteria) ─
df['Jargon/Technicality Density'] = 11 - df['Jargon/Technicality Density']

# ── 3. Standardize to mean 0, SD 1 ───────────────────────────────────────────
for col in LLM_COLS:
    m, s = df[col].mean(), df[col].std()
    df[col] = (df[col] - m) / s

# ── 4. Gender split: Fem50 (female if ≥50% authors are female) ───────────────
df['female'] = df['Female_authorship_ratio'] >= 0.5
female = df[df['female']]
male   = df[~df['female']]
print(f"Female papers: {len(female):,}   Male papers: {len(male):,}")

# ── 5. Compute difference in means + 95% CI for each criterion ───────────────
results = []
for col in LLM_COLS:
    f_vals = female[col].dropna().values
    m_vals = male[col].dropna().values
    diff   = f_vals.mean() - m_vals.mean()
    se     = np.sqrt(f_vals.var(ddof=1) / len(f_vals) + m_vals.var(ddof=1) / len(m_vals))
    ci_hw  = 1.96 * se
    pval = _ttest(f_vals, m_vals)
    results.append({
        'col':    col,
        'label':  DISPLAY[col],
        'diff':   diff,
        'ci_hw':  ci_hw,
        'pval':   pval,
    })

res = pd.DataFrame(results).sort_values('diff', ascending=False).reset_index(drop=True)

# ── 6. Filter to slide-10 criteria + Readability ─────────────────────────────
KEEP_COLS = {
    'Readability',
    'Jargon/Technicality Density',
    'Sentence Length & Directness',
    'Evidence & Citation Usage',
    'Pronoun Commitment',
    'Acknowledgement of Limitations',
    'Active/Passive Voice Ratio',
}
res = res[res['col'].isin(KEEP_COLS)].reset_index(drop=True)

# ── 7. Plot — horizontal bars for maximum label legibility ───────────────────
FONT_TICK  = 26
FONT_LABEL = 26

fig, ax = plt.subplots(figsize=(14, 8))
fig.patch.set_facecolor('white')
ax.set_facecolor('white')

# Sort ascending so largest diff is at the top
res = res.sort_values('diff', ascending=True).reset_index(drop=True)
y = np.arange(len(res))

ax.barh(
    y, res['diff'],
    color=PF_BLUE,
    alpha=0.85,
    height=0.6,
    zorder=3,
)

ax.errorbar(
    res['diff'], y,
    xerr=res['ci_hw'],
    fmt='none',
    color='#222222',
    capsize=6,
    capthick=2,
    elinewidth=2,
    zorder=4,
)

# Zero reference line
ax.axvline(0, color=PF_BLUE, linewidth=1.4, linestyle='--', alpha=0.7, zorder=2)

# ── Axes styling ──────────────────────────────────────────────────────────────
ax.set_yticks(y)
ax.set_yticklabels(res['label'], fontsize=FONT_TICK, color=AXIS_GRAY)
ax.tick_params(axis='x', labelsize=FONT_TICK, colors=AXIS_GRAY)
ax.tick_params(axis='y', which='both', left=False)

ax.set_xlabel('Difference in means (female − male)', fontsize=FONT_LABEL,
              color=AXIS_GRAY, labelpad=12)

# Remove spines
for spine in ax.spines.values():
    spine.set_visible(False)
ax.tick_params(axis='x', bottom=False)

# Light vertical grid
ax.xaxis.set_major_formatter(mticker.FormatStrFormatter('%.1f'))
ax.set_axisbelow(True)
ax.xaxis.grid(True, color=GRID_GRAY, linewidth=0.7, linestyle='-', alpha=0.7)

ax.set_ylim(-0.6, len(res) - 0.4)

plt.tight_layout()
fig.savefig(OUT_PATH, bbox_inches='tight', dpi=300)
print(f"Saved: {OUT_PATH.relative_to(ROOT)}")
plt.close()
