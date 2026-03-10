# Recent Changes

## Session: 2026-03-10

### Theme: Bug fix for `r(110)` program-already-defined error; `replication.tex` LLM outputs promoted from placeholders

---

### Bug fixes

#### 1. `Section-4.3.do` and `Section-4.3-llm.do` — `r(110)` program already defined

**Symptom:** When `hengel_master.do` reached `Section-4.3-llm.do`, Stata threw `program matching_figure already defined r(110)` and aborted.

**Root cause:** Both files had a typo on line 16: `capture programm drop matching_figure` (`programm` with double `m`). Stata does not recognise `programm`, so `capture` silently swallowed an invalid-command error instead of dropping the program. When `Section-4.3-llm.do` ran after `Section-4.3.do`, `matching_figure` was still in memory.

**Fix:** Corrected `programm` → `program` in both files:
```stata
capture program drop matching_figure
```

---

### `outputs/replication.tex` — LLM placeholders promoted to full references

All 19 `\maybeInput`/`\maybeInclude` placeholder calls replaced with standard `\input`/`\includegraphics` now that the corresponding Stata outputs exist.

**Figures (4):**
- `Figure-5-llm-base.pdf`, `Figure-5-llm-jel.pdf`, `Figure-5-llm-R.pdf`
- `Figure-G.1-llm-combo.pdf`

**Tables (15):**
- `Table-F.1-llm.tex`
- `Table-F.2-llm-FemRatio/Fem100/FemSolo/Fem1/Fem50/FemSenior.tex` (6 files)
- `Table-G.1-llm.tex`, `Table-G.2-llm.tex`, `Table-G.4-llm.tex`
- `Table-I.2-llm.tex`
- `Table-9-llm-base.tex`, `Table-9-llm-jel.tex`, `Table-9-llm-R.tex`
- `Table-J.3-llm.tex`

The `\maybeInput`/`\maybeInclude` macro definitions remain in the preamble for future use.

---

### `outputs/replication.tex` — LaTeX compilation fixes (this session)

Installed `tectonic` (`brew install tectonic`) and compiled `replication.tex` to `replication.pdf`. Required fixing several systematic bugs in the generated `.tex` table files:

#### 1. `siunitx` v3 rejects parenthesized standard errors

**Problem:** `S` columns in siunitx v3 try to parse numbers and reject `(0.02)` style entries.
**Fix:** Added `\sisetup{parse-numbers=false,table-number-alignment=center}` to the preamble. Numbers are already pre-formatted by Stata so this has no effect on rounding.

#### 2. Unescaped `&` in `\mrow{}{}` second arguments

**Problem:** Row labels like `\mrow{5cm}{Hedging Frequency & Type}` had bare `&` inside the second argument, causing LaTeX to treat it as a column separator.
**Affected files:** `Table-1-llm.tex` (4 instances), `Table-3-llm-*.tex` (6 files × 4 rows = 24 instances).
**Fix:** Script to escape `&` → `\&` inside `\mrow{}{...}` second arguments (excluding math mode).

#### 3. Unescaped `&` in direct LLM row labels (Table-5-llm-*)

**Problem:** `Table-5-llm-*.tex` files use row labels like `LLM G1: Creativity & Hedging` directly in table cells (not wrapped in `\mrow`).
**Affected files:** All 9 `Table-5-llm-*.tex` files, 4 rows each.
**Fix:** Replaced `& Hedging`, `& Voice`, `& Novelty`, `& Impact` → `\& Hedging`, etc.

#### 4. `\midrule` concatenated with next cell text

**Problem:** Stata's table writer concatenated `\midrule` with the first cell of the next row in some files (e.g., `\midruleEditor effects`).
**Affected files:** ~30+ table files across the project.
**Fix:** Script to insert newline + indentation after `\midrule` when immediately followed by a letter.

#### 5. Underscores in display text

**Problem:** Variable names like `_llm_readability_score` used directly as row labels caused "Missing \$" errors.
**Affected files:** All 9 `Table-5-*.tex` variants (both base and llm).
**Fix:** Replaced `_llm_readability_score` → `\_llm\_readability\_score` in those files.

#### 6. Column count mismatch in 3 appendix LLM tables (Stata bug)

**Problem:** `Table-G.1-llm.tex`, `Table-G.4-llm.tex`, and `Table-I.2-llm.tex` declare 5 S columns in their tabular spec and header, but the data rows have 11 values each. The corresponding `\multicolumn{5}{l}{...}` group labels also span only 5 columns.

**Root cause:** The Stata do-files (`Table-G.1-llm.do`, `Table-G.4-llm.do`, `Table-I.2-llm.do`) were written for 5 LLM composite groups but apparently export data for 11 model specifications (matching the Table-5-llm pattern). The column specs and headers were not updated to match.

**Temporary fix for PDF compilation:** Expanded the tabular spec to 11 S columns and added placeholder headers `(6)` through `(11)`. Updated `\multicolumn{5}{l}` → `\multicolumn{12}{l}` in `Table-I.2-llm.tex`.

**Permanent fix needed:** Review `Table-G.1-llm.do`, `Table-G.4-llm.do`, and `Table-I.2-llm.do` in Stata. Either:
- Reduce the exported data to 5 columns (one per LLM composite group), or
- Update the column specs and headers in the do-files to match the 11-column output.

---

### Updated Next Steps

- **Fix `tables.xlsx`** — open in Excel, force recalculation (Ctrl+Alt+F9), save to cache CONCATENATE formula results for `figure8/jel` and `figure8/R` in the `notes` sheet (needed to resolve `too few quotes r(132)` when `Section-4.3.do` calls `matching_figure, type(jel)`).
- **Re-run `hengel_master.do`** end-to-end after the `tables.xlsx` fix to confirm clean completion.
- **Fix column mismatch in `Table-G.1-llm.do`, `Table-G.4-llm.do`, `Table-I.2-llm.do`** — see item 6 above.
- **Create `0-code_summary/*.txt` files** for the 10 new LLM do-files.

---

## Session: 2026-03-09

### Theme: Stata bug fixes and replication.tex PDF hardening

---

### Bug fixes

#### 1. `Section-4.3.do` — conformability error r(503)

**Symptom:** After saving `author_matching_dik.dta`, Stata threw `conformability error r(503)` and aborted.

**Root cause:** The `foreach stat in flesch fleschkincaid gunningfog smog dalechall` loop (line 321) was missing `llm_readability`. The loop builds matrices (`bf1`, `sf1`, `nf1`, etc.) with 5 columns each, but the subsequent `ereturn_post` calls specified 6 column names (`flesch fleschkincaid gunningfog smog dalechall llm_readability`). A 5-column matrix paired with 6 column names is a conformability mismatch.

**Fix:** Added `llm_readability` to the loop:
```stata
foreach stat in flesch fleschkincaid gunningfog smog dalechall llm_readability {
```
This makes the loop consistent with: the merge's `keepusing` list, the reshape variable lists, `ereturn_post` colnames, and the `matching_figure` program's own loop.

**Note from previous session:** This bug was documented as a known issue in Section-4.3.5 design note ("5-stat/5-colname alignment"). The LLM version (`Section-4.3-llm.do`) naturally avoids it with 5 stats and 5 colnames.

---

#### 2. `Section-4.3.do` — "too few quotes" r(132) (diagnosed, not yet fixed)

**Symptom:** After writing `Table-9-jel.tex`, Stata threw `too few quotes r(132)` when `matching_figure, type(jel)` was called.

**Root cause:** In the `notes` sheet of `tables.xlsx` (the first sheet, which Stata reads by default), the `Note` cells for `figure8 / jel` and `figure8 / R` are Excel formula cells (`=CONCATENATE(VLOOKUP(...), "J.4.")` and `=CONCATENATE(VLOOKUP(...), "J.5.")`). These formulas have no cached value in the file (openpyxl returns `None` with `data_only=True`). When Stata's `import excel` encounters an uncached formula cell, it reads the formula text as a string literal. That text contains double quotes (e.g., `"J.4."`), which break Stata's string parsing when the note is embedded inside `wordwrap \`"{it:Notes.} \`note'"\`'`.

The `base` type worked because its Note is a plain string with no embedded quotes. This error was never reached in previous runs because the run aborted earlier at the r(503) error.

**Fix needed:** Open `tables.xlsx` in Excel, recalculate (Ctrl+Alt+F9), and save — this will cache the formula results so Stata reads the computed strings. Alternatively, replace the two CONCATENATE formulas in the `notes` sheet with literal strings.

---

### `outputs/replication.tex` — graceful handling of missing outputs

Added two helper macros to allow the PDF to compile even when some Stata outputs have not yet been generated:

```latex
\newcommand{\maybeInput}[1]{\IfFileExists{#1}{\input{#1}}{\textit{[Not yet generated: \texttt{#1}]}}}
\newcommand{\maybeInclude}[1]{\IfFileExists{#1}{\includegraphics[width=\textwidth]{#1}}{\centering\textit{[Not yet generated: \texttt{#1}]}}}
```

Applied `\maybeInclude` to 4 missing figures and `\maybeInput` to 15 missing tables — all outputs from LLM do-files that have not yet run to completion:

| Missing figures | Missing tables |
|---|---|
| `Figure-5-llm-base/jel/R.pdf` | `Table-F.1-llm.tex` |
| `Figure-G.1-llm-combo.pdf` | `Table-F.2-llm-*` (6 variants) |
| | `Table-G.1/G.2/G.4-llm.tex` |
| | `Table-I.2-llm.tex` |
| | `Table-9-llm-base/jel/R.tex` |
| | `Table-J.3-llm.tex` |

Once those do-files run successfully, the files will be picked up automatically on the next PDF compile.

---

### Updated Next Steps

- **Fix `tables.xlsx`:** Open in Excel, force recalculation (Ctrl+Alt+F9), and save to cache the CONCATENATE formula results for `figure8/jel` and `figure8/R` in the `notes` sheet.
- **Re-run `hengel_master.do`** end-to-end to generate remaining LLM outputs.
- **Compile `replication.pdf`** once LaTeX is installed (`brew install --cask mactex`) or via Overleaf upload.

---

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
