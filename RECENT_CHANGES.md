# Recent Changes

## Session: 2026-03-07

### Theme: LLM composite score versions of all readability tables/figures

Created 10 new do-files that mirror every table and figure iterating over readability scores (`flesch fleschkincaid gunningfog smog dalechall llm_readability`), but using the 5 LLM tonal composite groups (`llm_g1 llm_g2 llm_g3 llm_g4 llm_g5`) instead. Updated `hengel_master.do`, `tables.xlsx`, and `replication.tex` accordingly.

---

### New do-files created (in `0-code/output/`)

#### Tier 1: Simple foreach loops

| File | Source | Description |
|---|---|---|
| `Table-F.1-llm.do` | `Table-F.1.do` | Journal-level LLM tonal composite differences vs AER |
| `Table-G.1-llm.do` | `Table-G.1.do` | NBER regressions (first panel), full output |
| `Table-G.2-llm.do` | `Table-G.2.do` | NBER FE change-in-score (second panel), full output |
| `Table-G.4-llm.do` | `Table-G.4.do` | Semi-blind review variant (Year>1997) |
| `Table-I.2-llm.do` | `Table-I.2.do` | Author first/mean/last paper scores; `\multicolumn{6}` → `\multicolumn{5}` |

#### Tier 2: Program reuse (only table-output program redefined)

| File | Source | Description |
|---|---|---|
| `Table-3-llm.do` | `Table-3.do` | Article-level gender regressions, 7 specs (no R variant) |
| `Table-F.2-llm.do` | `Table-F.2.do` | Author-level Arellano-Bond, 6 specs (no R variant) |

#### Tier 3: Program redefinition for substantive fix

| File | Source | Description |
|---|---|---|
| `Table-5-llm.do` | `Table-5.do` | NBER FE/FGLS peer review impact, 9 specs (no R variant); `estimates restore ols*_fleschkincaid` → `ols*_llm_g1` |

#### Tier 4: Figure

| File | Source | Description |
|---|---|---|
| `Figure-G.1-llm.do` | `Figure-G.1.do` | Blind review event study; outputs `Figure-G.1-llm-combo.pdf` |

#### Tier 5: Complex multi-section

| File | Source | Description |
|---|---|---|
| `Section-4.3-llm.do` | `Section-4.3.do` | Mahalanobis matching → `Table-9-llm-*.tex`, `Figure-5-llm-*.pdf`, `Table-J.3-llm.tex`; saves `author_matching_llm` and `author_matching_dik_llm` |

---

### Supporting changes

#### `hengel_master.do` — 10 new include lines

Each placed immediately after its original:
```
include "0-code/output/Table-3-llm.do"      (after Table-3.do)
include "0-code/output/Table-5-llm.do"      (after Table-5.do)
include "0-code/output/Section-4.3-llm.do"  (after Section-4.3.do, before Figure-K.1.do)
include "0-code/output/Table-F.1-llm.do"    (after Table-F.1.do)
include "0-code/output/Table-F.2-llm.do"    (after Table-F.2.do)
include "0-code/output/Table-G.1-llm.do"    (after Table-G.1.do)
include "0-code/output/Table-G.2-llm.do"    (after Table-G.2.do)
include "0-code/output/Figure-G.1-llm.do"   (after Figure-G.1.do)
include "0-code/output/Table-G.4-llm.do"    (after Table-G.4.do)
include "0-code/output/Table-I.2-llm.do"    (after Table-I.2.do)
```

#### `data/raw/hengel_labels/tables.xlsx` — 35 new rows added via openpyxl

Two categories of entries:

**Columns = LLM groups (5-column layout, explicit CellWidth/Header):**
- `table3llm | journal` — journal comparisons
- `table6llm | full` — NBER full output (first panel)
- `table6llm | change_full` — NBER full output (second panel)
- `tableH1llm` — first/mean/last scores
- `table7_semiblindllm` — semi-blind review

**Columns = model specs (same layout as originals):**
- `table3llm` — 7 gender specs (FemRatio through FemJunior)
- `table6llm` — 9 specs (7 gender + wordlimit + jel)
- `table4llm` — 6 gender specs (FemRatio through FemSenior)
- `table8llm` — 3 matching specs (base, jel, R)
- `Rit_regresultsllm` — regression output for Rit
- `figure8llm` — 3 figure note entries (base, jel, R)

All values written explicitly (no VLOOKUP formulas, since new tablenames can't resolve against the existing named range).

#### `outputs/replication.tex` — 36 new LLM references added

New sections/subsections for:
- Table 3 LLM (7 types): `Table-3-llm-*.tex`
- Table 5 LLM (9 types): `Table-5-llm-*.tex`
- Table 9 LLM (3 types): `Table-9-llm-*.tex`
- Table J.3 LLM: `Table-J.3-llm.tex`
- Table F.1 LLM: `Table-F.1-llm.tex`
- Table F.2 LLM (6 types): `Table-F.2-llm-*.tex`
- Tables G.1, G.2, G.4 LLM: `Table-G.1-llm.tex`, `Table-G.2-llm.tex`, `Table-G.4-llm.tex`
- Table I.2 LLM: `Table-I.2-llm.tex`
- Figures 5 LLM (3 types): `Figure-5-llm-*.pdf`
- Figure G.1 LLM: `Figure-G.1-llm-combo.pdf`

---

### Key design decisions

1. **No R variant** — LLM do-files skip the `stats(r_fleschkincaid r_gunningfog r_smog)` calls since there's no alternative-package equivalent for LLM scores.

2. **Program name collisions are safe** — Programs redefined in LLM files (`article_level_table`, `nber_fgls`, `nber_table`, `author_level_table`, `matching_table`, `matching_figure`) overwrite the originals. This is safe because LLM files run AFTER their originals, and the original programs are never called again afterward.

3. **`nber_fgls` hardcoded fix** — The original `estimates restore ols*_fleschkincaid` (lines 69, 74, 80) was changed to `estimates restore ols*_llm_g1` in the redefined version, since the LLM version stores `ols_llm_g1` estimates.

4. **Section-4.3 5-stat/5-colname alignment** — The original has 5 stats in one loop but 6 colnames in `ereturn_post` (a pre-existing bug). The LLM version naturally avoids this (5 stats, 5 colnames).

---

### Next Steps

#### A. Complete a clean full run of `hengel_master.do`
The run has not been tested end-to-end since these changes. All 10 new LLM do-files need to execute without errors. Potential issues:
- Estimate name collisions if `estimates clear` is missing at the right points
- Variable existence in datasets (all LLM composites should already be in main datasets from prior Data.do consolidation)

#### B. Verify new `.tex` files appear in `outputs/tables/tex/`
After the Stata run, confirm all expected output files are produced:
- 7 × `Table-3-llm-*.tex`
- 9 × `Table-5-llm-*.tex`
- `Table-F.1-llm.tex`
- 6 × `Table-F.2-llm-*.tex`
- `Table-G.1-llm.tex`, `Table-G.2-llm.tex`, `Table-G.4-llm.tex`
- `Table-I.2-llm.tex`
- 3 × `Table-9-llm-*.tex`
- `Table-J.3-llm.tex`

#### C. Verify new figures appear in `outputs/figures/`
- `Figure-G.1-llm-combo.pdf`
- 3 × `Figure-5-llm-*.pdf`

#### D. Recompile `replication.tex` in Overleaf
All new `\input{}` and `\includegraphics{}` entries need the corresponding files from Steps B and C. Verify rendering of LLM group labels in table headers.

#### E. Create `0-code_summary/*.txt` files for new do-files
The 10 new LLM do-files don't yet have corresponding summary files in `0-code_summary/`.

#### F. Update `\mcol` macro width if needed
The `\mcol` macro is hardcoded as `\multicolumn{6}{l}` — this works for `Table-F.2-llm` (5 LLM columns + 1 label = 6), but verify it's not used elsewhere with a different column count.
