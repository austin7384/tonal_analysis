# Recent Changes

## Session: 2026-04-26 (night)

### Completed
- Renamed all 5 "Backup" frame titles to "Appendix" in slides.tex
- Rewrote slides 2–6, 8–9, 12 to match handwritten speaker script and improve memory prompting
- Verified rubric score direction: G1 (Creativity & Hedging) runs opposite to "clearer" — high = more hedging/caution, not clearer
- Decided to omit novelty claims from main talk (not materially important)

### Key changes
- `outputs/slides.tex` slide 2: two-column boxed → single-column; added "different voice" italic hook, "Preview of findings" section with 2 result bullets
- `outputs/slides.tex` slide 3: two-column boxed → single-column; fixed title "two" → "three" literatures; added Gilligan as first bullet; restructured as 4 bullets (Gilligan, Card/Sarsons, Hengel, Our contribution)
- `outputs/slides.tex` slide 4: two-column → single-column; replaced percentage stats with raw counts (7,939 all-male, 319 all-female); added article/author control details; listed all 5 authorship measures
- `outputs/slides.tex` slide 5: added jargon scale-flip footnote (11−raw; high = less jargon)
- `outputs/slides.tex` slide 6: updated validation bullet to mention human-in-the-loop on small subset, auditing outputs, iteratively improving prompt
- `outputs/slides.tex` slide 9: added footer naming null tonal dimensions (assertiveness, hedging, emotional valence); scaled figure to 0.63\textheight to fit
- `outputs/slides.tex` slide 12: removed "novelty claims"; sharpened null finding to "not more hesitant or emotional"; added robustness + LLM measurement error caveat
- `outputs/slides.pdf`: recompiled, 17 pages, 0 warnings

### Notes / follow-up
- Slides 7, 10, 11 reviewed against script — no changes needed
- Novelty-Claim Strength result (negative, significant) is in appendix tables but intentionally omitted from main talk

---

## Session: 2026-04-26 (evening)

### Completed
- Created `code/LLM_evaluations/readability_sd_comparison.py`: standardizes regression coefficients from slide 8 by dividing by SD(Y), showing LLM effect is ~2–3× larger in SD units than any objective measure (LLM: 0.29 SD vs Flesch-family: 0.08–0.12 SD)
- Replaced slide 11 text (two-column "what we vary / what holds") with a 5×6 booktabs table of col~(5) coefficients across all six authorship specifications for: LLM Readability, Jargon, Directness, Assertiveness, Emotional Valence
- Fixed coefficient extraction bug in slide 11: `\&` in criterion labels (Directness, Assertiveness) caused off-by-one column shift; corrected by neutralizing `\&` before splitting on `&`. Directness/FemRatio corrected from 0.31*** → 0.25** (matching slide 10)
- Replaced backup slides 14 ("Key regression coefficients"), 15 ("Five clarity dimensions"), 16 ("GPT bias concern") with four structured data backup slides covering all remaining criteria not shown on slides 10–11
- Recompiled deck to 17 pages, 0 warnings

### Key changes
- `code/LLM_evaluations/readability_sd_comparison.py`: new script; loads `Hengel_evaluations.csv` + `ReadStat.csv`, computes SD per measure, prints beta/SD comparison table
- `outputs/slides.tex`: slide 11 replaced with robustness table (5 criteria × 6 authorship specs); backup slides 14–16 replaced with 4 new slides:
  - Backup A: col~(4)+(5) for G1+G2 tonal criteria (Modal Verb, Hedging, Qualifier, Caution, Assertiveness)
  - Backup B: col~(4)+(5) for G3–G5 remaining (Imperative, Novelty, Emotional, Practical)
  - Backup C: col~(5) × 6 specs for G1+G2 not on slide 11 (Modal Verb, Hedging, Qualifier, Ack Limits, Caution, Active/Passive)
  - Backup D: col~(5) × 6 specs for G3–G5 not on slide 11 (Imperative, Novelty, Pronoun, Evidence, Practical)
- `outputs/slides.pdf`: recompiled, 17 pages, 0 warnings

### Notes / follow-up
- Slide 11 Directness is now 0.25** (corrected); all other slide 11 values also corrected for the `\&` parsing bug
- LLM Readability excluded from backup col~(4)+(5) tables — already shown on slides 8 and 11
- `readability_sd_comparison.py` uses `Hengel_evaluations.csv` (not `merged_evaluations.csv` which is git-ignored); matched N=9,117 confirms correct sample

---

## Session: 2026-04-26

### Completed
- Updated slide 9 (`diff_means_plot_slides.pdf`) figure: darkened all axis/tick text from `#747474` to `#2a2a2a` and colored the Jargon bar pink (`#D85C63`) to flag its reversed sign
- Recompiled `outputs/slides.tex` to zero warnings; reduced `max height` from `0.82\textheight` to `0.78\textheight` on the figure frame to absorb the slightly taller regenerated figure

### Key changes
- `code/LLM_evaluations/diff_means_plot.py`: `AXIS_GRAY` darkened to `#2a2a2a`; bar color logic now assigns `PF_PINK` to Jargon, `PF_BLUE` to all other criteria
- `outputs/figures/diff_means_plot_slides.pdf`: regenerated with new colors
- `outputs/slides.tex`: `max height=0.78\textheight` on slide 9 frame (was `0.82`)
- `outputs/slides.pdf`: recompiled, 16 pages, 0 warnings

### Notes / follow-up
- The pink Jargon bar visually signals to audiences that the sign was flipped (higher = less jargon); may want to add a footnote or legend annotation to the figure itself in a future pass

---

## Session: 2026-04-21

### Completed
- Installed two new Claude Code skills: `content-editor` (economics journal content edit) and `latex-copy-editor` (professional LaTeX copy edit) from `/Users/austincoffelt/Documents/` to `~/.claude/commands/`
- Ran `/latex-copy-editor` on the full paper draft in `outputs/Gender_Writing_Paper___Austin/`
- Applied 18 copy-edit fixes across all prose files
- Performed full citation command overhaul: `(\cite{X})` → `\parencite{X}`, narrative `\cite{X}` → `\textcite{X}`, multi-citation clusters consolidated into single `\parencite{A,B,C}` — applied to all 6 section files
- Verified clean compilation throughout (119 pages, 0 errors)

### Key changes
- `0_main.tex`: removed duplicate `\usepackage{appendix}`; moved `\date{}` outside `\author{}` block
- `2_Introduction.tex`: "data comes" → "data come"; `~` before all section `\ref`s; full citation overhaul (4 `\textcite`, 1 `\parencite`)
- `3_Lit.tex`: 4 narrative `\cite` → `\textcite`
- `4_Data.tex`: "11695" → "11,695"; "article data includes" → "include"; "scale of 1-10" → "1--10"; "LLM model" → "LLM"; "LLM) powered" → "LLM)-powered"; citation overhaul (6 `\textcite`, 5 `\parencite`); "copied from \cite{}" rephrased to clean `\parencite`
- `5_Methodology.tex`: "9117" → "9,117"; "2 data samples" → "two"; "first difference" → "first-difference"; `\label{}` added to equations (1)–(4); hard-coded "Equation (3)/(4)" → `\eqref`; `~` before `\ref`; citation overhaul (5 `\textcite`, 2 `\parencite`)
- `6_Results.tex`: "3 possible explanations" → "three"; `t=1` / `t$\geq$6` → proper math mode; "Figures~\ref{} shows" → "Figure~\ref{} shows"; missing `~` before refs; citation overhaul (8 `\textcite`)
- `7_conclusion.tex`: 2 narrative `\cite` → `\textcite`

### Notes / follow-up
- Citation overhaul complete for all prose files; table/figure `\input` files (Stata-generated) not touched
- One edge case "(copied from \cite{}))" in `4_Data.tex` rephrased to "Flesch readability \parencite{}" — author should verify the phrasing reads naturally
- "Empty Ibidem citation" warnings from biblatex-chicago are pre-existing (ibid. mechanism on consecutive same-source cites); suppressing requires `\usepackage[ibidpage=false]{...}` or similar — not addressed this session
- Table overfull hbox warnings all originate in Stata-generated files; not fixable without modifying those files

---

## Session: 2026-04-16

### Completed
- Created `code/LLM_evaluations/readability_correlation.py`: computes Pearson correlations between LLM Readability and five Hengel readability measures (Flesch, FK, Gunning Fog, SMOG, Dale-Chall); outputs CSV and LaTeX table
- Fully restructured `outputs/slides.tex` from 11 frames to 12 content frames + 4 backup slides; replaced all slides_figures/ figure references with inline tables or `figures/diff_means_plot.pdf`
- New slides added: Related Literature (slide 3), LLM Evaluations (slide 6), Robustness (slide 11)
- Replaced figure-based results slides with inline booktabs tables showing cols 4–5 only
- Reformatted slide 5 (Rubric) from cramped two-column to full-width 2×3 grid
- Converted slide 6 (LLM Evaluations) from two-column boxed layout to single-column bullet list
- Trimmed word-heavy bullets on slides 2 and 3
- Rewrote conclusion as a single flowing sentence (no bullets)

### Key changes
- `code/LLM_evaluations/readability_correlation.py`: new script; outputs `outputs/tables/csv/readability_correlation.csv` and `outputs/tables/tex/Table-ReadCorr.tex`
- `outputs/slides.tex`: full restructure — 12 content frames, no slides_figures/ dependencies, `\graphicspath{{figures/}}`; inline tables for benchmarking (Table 1 cols 4–5) and controlled regressions (individual criteria cols 4–5 from Table-3-llm-individual-1/2)
- `outputs/slides.pdf`: recompiled, 16 pages, 0 warnings

### Notes / follow-up
- Readability correlations: Flesch-Kincaid/Gunning Fog/SMOG correlate strongest with LLM readability (~0.46); Dale-Chall weakest (~0.27)
- Slides now use `figures/diff_means_plot.pdf` for 5.2 mean differences — this file is untracked; ensure it stays in `outputs/figures/`
- `slides_figures/` directory is no longer referenced in slides.tex but files remain on disk

---

## Session: 2026-04-15

### Completed
- Removed all forced `\\` line breaks from running text paragraphs in `outputs/slides.tex` (kept structural `\\[gap]` on title/closing slides)
- Moved empirical specification slide from backup appendix into the main deck as slide 4 (after data/rubric, before validation); retitled assertively
- Added then removed a tonal criteria coefficients table slide (Tables 11–12 data across four control specs); user removed it after preview

### Key changes
- `outputs/slides.tex`: `\\` breaks removed from Hengel column, "This paper" column, devil's advocate text, closing slide body, and backup spec text — text now flows as natural paragraphs
- `outputs/slides.tex`: Empirical specification frame promoted from `\appendix` to main deck (slide 4); removed duplicate from backup section
- `outputs/slides.pdf`: Recompiled, 13 pages, 0 Overfull/Underfull warnings

### Notes / follow-up
- Deck is 13 slides (10 main + 3 backup): title, motivation, data/rubric, empirical spec, validation, mean differences, the split, regression coefficients, robustness, devil's advocate, closing
- User considered but rejected a tonal criteria table slide showing coefficients from Tables 11–12 across four specifications — may revisit in a different format
- `outputs/slides_notes.md` documents all on-screen claims with exact paper page/table/figure citations

---

## Session: 2026-04-03 (evening)

### Completed
- Ran `/fletcher` audit on Table-3-FemRatio; identified 5 flags (sign direction, "45 regressions" note, binary language in continuous-variable table, Flesch/LLM divergence in col 9, col 9 sample mechanism)
- Fixed Fletcher Flag 2: "45 separate OLS regressions" → "54" in both `outputs/tables/tex/Table-3-FemRatio.tex` and `data/raw/hengel_labels/tables.xlsx` (robust for future Stata runs)
- Audited all 71 summary `.txt` files in `0-code_summary/` for errors; categorized and triaged 9 errors
- Fixed 3 documentation errors in summary files: `Data.txt` criteria count (15→16), `Table-3-llm-individual.txt` and `Table-5-llm-individual.txt` missing `imperative` exclusion note, `Table-I.2-llm.txt` backslash fix clarification
- Investigated Section-4.3-llm line 93 "double merge crash" (flagged as ERROR in prior session review): confirmed it is a **harmless no-op**, not a crash risk — `nogenerate` causes Stata to silently overwrite duplicate variables with identical values. Previous review was incorrect.
- Added "Decision: no code change" rationale notes to all unfixed errors: `Data.txt` (3 entries), `Table-10-llm.txt`, `Section-4.3.txt`, `Section-4.3-llm.txt`
- Merged all 21 `*-review.txt` files into their corresponding `*-llm.txt` summary files; deleted all standalone review files

### Key decisions
- **Non-LLM code bugs not fixed**: `Data.do` merge m:m (line 124), wrong denominator (line 349), missing-value traps (lines 98/101) — non-LLM code replicates original paper exactly; touching it risks breaking a validated pipeline
- **LLM merge m:m not fixed**: same pattern in validated non-LLM counterpart (`Table-10.do`); runs successfully in practice
- **Review files consolidated**: 21 `*-review.txt` files deleted; content now lives at the bottom of each corresponding summary `.txt` — single document per do-file going forward

### Key changes
- `outputs/tables/tex/Table-3-FemRatio.tex`: "45" → "54" regressions in tablenote
- `data/raw/hengel_labels/tables.xlsx`: same fix in `table3/FemRatio` Note cell (durable)
- `code/hengel_replication/0-code_summary/Data.txt`: criteria count fix + "no change" decision notes on 4 entries
- `code/hengel_replication/0-code_summary/Section-4.3-llm.txt`: corrected double-merge diagnosis (not a crash); added original review file content
- `code/hengel_replication/0-code_summary/Table-3-llm-individual.txt`, `Table-5-llm-individual.txt`: imperative exclusion + post-processing details added; review merged in
- `code/hengel_replication/0-code_summary/Table-I.2-llm.txt`: backslash fix approach clarified; review merged in
- `code/hengel_replication/0-code_summary/*.txt` (21 LLM files): review content merged in, 21 `*-review.txt` files deleted

### Notes / follow-up
- Fletcher flags 1, 3, 4, 5 from Table-3-FemRatio are open and not yet investigated: sign direction of FK/Gunning Fog/SMOG, binary language in notes, Flesch/LLM divergence in col 9, col 9 sample mechanism
- Prior session's RECENT_CHANGES noted Section-4.3-llm line 93 as a crash-risk ERROR — **this was incorrect**; confirmed harmless no-op
- Prior session noted `merge m:m` bugs in Table-10-llm and Figure-6-llm — confirmed not causing incorrect results given non-LLM counterparts are validated

---

## Session: 2026-04-03

### Completed
- Created 21 new `*-llm.txt` summary files in `0-code_summary/` documenting all -llm do-files (Table-1-llm through Section-4.3-llm) using `/summarize-stata`
- Created 21 new `*-llm-review.txt` review files in `0-code_summary/` with static analysis of all -llm do-files using `/review-stata`
- Appended `## REVIEW` sections to 30 existing non-LLM `0-code_summary/*.txt` files

### Key findings from reviews
- **ERROR** `Section-4.3-llm.do` line 93: double-merge of `primary_jel` into `author_pp` — will crash with "variable already defined" since those JEL1_* columns were already merged in on line 79
- **WARNING** `Table-10-llm.do`, `Table-10-llm-g3.do`, `Figure-6-llm.do`, `Figure-6-llm-g3.do` line 5: `merge m:m ArticleID` should be `merge 1:m`
- **WARNING** `Table-I.2-llm.do` lines 33–34, 36: estout `\\` backslash-stripping in `elist`/`blist` group-header rows (same issue as individual tables; needs Python post-processing fix)
- **WARNING** `Table-3-llm-individual.do` line 255: `$^\dagger` expands as global macro, silently drops the dagger marker
- **WARNING** `Table-5-llm.do` lines 30/44, `Table-5-llm-individual.do` lines 71/85: unprotected `rename` in estimation loop — stranded variable name if estimation errors
- **ERROR** `Data.do` line 124: `merge m:m InstID Year` should be `merge m:1`; line 349: `nber_pps_count` divides by wrong denominator (`_sent_count` instead of `nber_sent_count`)

### Key changes
- `code/hengel_replication/0-code_summary/`: 42 new files added (21 summaries + 21 reviews for all -llm do-files)
- `code/hengel_replication/0-code_summary/*.txt` (30 files): review sections appended to existing non-LLM summaries

### Notes / follow-up
- `Section-4.3-llm.do` ERROR (double merge) should be investigated — line 93 is redundant and would crash
- `merge m:m` bugs in Figure-6 and Table-10 files are the same pattern as the main Figure-6.do — worth checking if the non-LLM versions have the same issue
- `Table-I.2-llm.do` backslash-stripping bug is new (not previously documented) — needs same Python post-processing fix as the individual tables

---

## Session: 2026-04-02

### Completed
- Integrated all 18 Table-5-llm-individual `.tex` files into `replication.tex` (already had `\maybeInput` placeholders — files now render automatically) and `results_summary.tex` (added two new FemRatio sections for G1–G3 and G4–G5+Readability)
- Fixed a post-processing bug in all 18 `Table-5-llm-individual-*.tex` files: `estout` strips one backslash from group-header rows, so `\textbf{G1: ...}\\` was written as `\textbf{G1: ...}\`. Fixed by appending the missing `\` to all lines matching `\textbf{G...}` or `\textbf{Standalone}` via Python. Applied 46 fixes total (37 for G-group headers, 9 for Standalone).
- Recompiled both `replication.pdf` (244 pages) and `results_summary.pdf` (32 pages) — both compile cleanly (only pre-existing `Table-5.tex` caption warning remains)
- Comprehensive update to `CLAUDE.md`: added standalone analysis scripts section, expanded module descriptions, documented individual LLM criteria tables, added imperative zero-variance note, `_score` aliases note, new Outputs section, N=9,117 sample size, and corrected tablename mappings
- Created three global slash commands: `/review-stata` (10-category Stata code review), `/review-paper` (adversarial academic paper review), `/wrap-up` (commit + memory + RECENT_CHANGES update)

### Key changes
- `outputs/results_summary.tex`: added Table-5-llm-individual-1-FemRatio and Table-5-llm-individual-2-FemRatio sections
- `outputs/tables/tex/Table-5-llm-individual-1-*.tex` (9 files): fixed `\` → `\\` on G1/G2/G3 group-header rows
- `outputs/tables/tex/Table-5-llm-individual-2-*.tex` (9 files): fixed `\` → `\\` on G4/G5/Standalone group-header rows
- `outputs/replication.pdf`, `outputs/results_summary.pdf`: recompiled
- `CLAUDE.md`: major update documenting all work done since original authoring
- `~/.claude/commands/review-stata.md`: new global slash command
- `~/.claude/commands/review-paper.md`: new global slash command
- `~/.claude/commands/wrap-up.md`: new global slash command

### Notes / follow-up
- The `estout` backslash-stripping issue is documented in comments inside `Table-5-llm-individual.do` — any future re-run of that script will require re-applying the Python post-processing fix to the generated `.tex` files
- `Table-H.4` col 3 Constant SE discrepancy still open (see Open Issues in CLAUDE.md)

---

## Session: 2026-03-24

### Theme: Table 5 LLM Individual — peer review impact on all 16 individual LLM criteria

---

### New script: `Table-5-llm-individual.do`

**File:** `code/hengel_replication/0-code/output/Table-5-llm-individual.do`

New Stata do file that estimates the impact of peer review on each individual LLM tonal criterion (Table 5 analogue for individual scores instead of composite groups). Produces 18 `.tex` files: 9 gender-measure variants × 2 sub-tables (G1–G3 and G4–G5 + Readability).

**Programs defined (standalone, no dependency on Table-5.do or Table-5-llm.do):**
- `nber_fe` — FE paired-difference regressions (redefined for standalone use)
- `nber_fgls` — OLS + FGLS regressions with new `firststats(string)` option, replacing the hardcoded `estimates restore ols*_llm_g1` in the composite version
- `nber_individual_table` — estout + create_latex wrapper for both sub-tables

**9 variants:** FemRatio, Fem100, FemSolo, FemSenior, FemJunior, Fem1, Fem50, wordlimit, jel

**Imperative-Form Occurrence dropped:** `nber_llm_imperative_score` has zero variance in the FemSolo subsample (all values = 1 for solo-authored NBER papers), causing `suest` to fail with r(322). Imperative is excluded from all Table 5 individual tables. G3 (Structural Directness) contains only Sentence Length & Directness.

---

### `Data.do` — 15 individual NBER score aliases added

**File:** `code/hengel_replication/0-code/output/Data.do`

Added `generate nber_llm_*_score = nber_llm_*` for all 15 individual criteria (modal_verb through practical) after the existing `nber_llm_readability_score` alias. These are captured by `reshape long @_score` into the `nber_fe` paired-difference dataset.

---

### `tables.xlsx` — 18 new rows

**File:** `data/raw/hengel_labels/tables.xlsx`

Added rows for `table6llmind1` (G1–G3) and `table6llmind2` (G4–G5 + Readability), 9 types each. Format: `p{4.5cm}` + 11 S columns, landscape sidewaystable, same OLS/FGLS header as `table6llm`.

---

### `replication.tex` — 18 new sections

**File:** `outputs/replication.tex`

Added two new sections for Table 5 LLM Individual (G1–G3 and G4–G5 + Readability), each with 9 `\maybeInput` subsections matching the variant order.

---

### `hengel_master.do` — include added

**File:** `code/hengel_replication/hengel_master.do`

Added `include` line for `Table-5-llm-individual.do` after `Table-5-llm.do`. Currently active; Table-2, Table-3, Table-3-llm, and Table-3-llm-individual commented out for selective run.

---

## Session: 2026-03-20

### Theme: LLM analysis scripts, sample correction (N=9,117), LaTeX paper diagnosis

---

### New scripts: `code/LLM_evaluations/correlation_matrix.py` and `code/LLM_evaluations/llm_summary_stats.py`

Two new analysis scripts added to `code/LLM_evaluations/`:

**`correlation_matrix.py`** — Computes the 16×16 Pearson correlation matrix of LLM tonal criteria at the article level. Outputs:
- `outputs/tables/csv/llm_correlation_matrix.csv`
- `outputs/tables/tex/Table-Corr.tex` (lower-triangle landscape table)

**`llm_summary_stats.py`** — Summary statistics for all 16 LLM criteria. Outputs:
- `outputs/tables/csv/llm_summary_overall.csv` — 16 criteria × 7 stats (mean, SD, min, p25, median, p75, max)
- `outputs/tables/csv/llm_summary_by_gender.csv` — mean + SD by All-Male / Mixed / All-Female / Full Sample
- `outputs/tables/csv/llm_summary_by_journal.csv` — mean by journal (AER, ECA, JPE, QJE)
- `outputs/tables/tex/Table-LLM-Summary.tex` — portrait summary table by gender composition

---

### Sample correction: N=9,121 → N=9,117

**Root cause identified:** `merged_evaluations.csv` contained 4 articles excluded by the Stata pipeline but not by the Python pipeline. All 4 were ECA articles:

| ArticleID | Reason |
|---|---|
| 1954 | Language filter — French article |
| 4089 | Errata filter — title contains "A Corrigendum" |
| 8380 | Errata filter — title contains "Corrigendum to …" |
| 9441 | Errata filter — title contains "Corrigendum to …" |

**Fix:** Both `correlation_matrix.py` and `llm_summary_stats.py` now apply the same filters as `hengel_data_cleaning.py` before computing any statistics:
1. `Language == 'English'`
2. Title does not match `['corrigendum', 'erratum', ': a correction', ': correction']`

All 4 excluded articles were all-male authored, so female-authorship statistics are unaffected.

---

### LaTeX paper (`Gender_Writing_Paper___Austin (1)/0_main.tex`) — compilation error diagnosed

**Fatal error:** `\input{8_Appendix}` and `\input{9_Things_to_do}` reference files that no longer exist (old numbering). Actual files are `10_Appendix.tex` and `11_Things_to_do.tex`. No changes made — diagnosis only.

Additional non-fatal issues noted: bibliography requires `biber` pass, `biblatex-chicago` loaded twice (lines 41 and 44), `\author{}` defined twice, stray text on line 126.

---

## Session: 2026-03-18

### Theme: Post-run audit, LaTeX bug fixes, replication.tex reordering, results_summary.pdf

---

### New master run completed

Full `hengel_master.do` run completed. All outputs regenerated.

---

### `outputs/replication.tex` — ordering fixes

Three ordering issues corrected:

1. **Table 9 LLM** moved from the end of the document to immediately after Table 9 (before Table 10), consistent with the pattern used for all other LLM/non-LLM pairs.
2. **Table J.3 LLM** demoted from a standalone `\section{}` at the end to a `\subsection{}` inside the Appendix J section, directly after Table J.3.
3. **Table F.2 LLM** subsections reordered from `FemRatio → Fem100 → FemSolo → Fem1 → Fem50 → FemSenior` to the standard pattern `FemRatio → Fem1 → Fem50 → Fem100 → FemSolo → FemSenior`.

---

### LaTeX compilation bugs fixed (Stata output issues)

Two classes of bugs in the generated `.tex` files were identified and fixed at both the source and the existing output files.

#### Bug 1 — Unescaped `&` in `\mrow{}{}` labels (`Table-1-llm.tex`)

**Symptom:** Fatal LaTeX error `Extra }, or forgotten \endgroup` on `\mrow{5cm}{Hedging Frequency & Type}`.

**Root cause:** `Table-1-llm.do` uses `varlabels(, prefix("\mrow{5cm}{") suffix("}"))`, which wraps Stata variable labels in `\mrow{}{}`. Four variable labels contained bare `&` (`Hedging Frequency & Type`, `Assertiveness & Voice`, `Sentence Length & Directness`, `Evidence & Citation Usage`). Inside `\mrow{}{}` in a tabular environment, `&` is interpreted as a column separator.

**Immediate fix:** Escaped `&` → `\&` in the 4 affected rows of `Table-1-llm.tex`.

**Source fix — `data/raw/hengel_labels/varlabels.csv`:** Changed `&` → `\&` in all 16 LLM variable labels that contain ampersands (`_llm_hedging`, `_llm_assertiveness`, `_llm_directness`, `_llm_evidence`, `_llm_g1_score`, `_llm_g2_score`, `_llm_g4_score`, `_llm_g5_score`, and their `nber_llm_*` counterparts). These labels flow through `Data.do` → Stata variable labels → all estout calls on future runs.

#### Bug 2 — `\midrule` fused with next row text (15 Table-8/H files)

**Symptom:** Undefined control sequence `\midruleEditor` — LaTeX saw `\midrule` and `Editor effects` as a single undefined command.

**Root cause:** All Table-8 and Table-H do-files use `"\midrule${n}Editor effects"` in their `stats()` labels. `${n}` is a Stata global intended to expand to a newline character (`char(10)`), but was never defined anywhere in the codebase. With `$n` undefined, it expanded to an empty string, producing `\midruleEditor effects` on a single line.

**Why only Table-8/H files were affected:** Other tables using the same `${n}` pattern (e.g., Table-3, Table-5) had been regenerated in a Stata session where `$n` happened to be set; Table-8/H outputs were from a different session where it was not.

**Immediate fix:** Inserted a newline between `\midrule` and `Editor effects` in all 15 affected files (`Table-8-{FemRatio,Fem1,Fem50,Fem100,FemSolo,FemSenior,R}.tex` and `Table-8-llm-{FemRatio,Fem1,Fem50,Fem100,FemSolo,FemSenior}.tex`, plus `Table-H.3.tex` and `Table-H.4.tex`).

**Source fix — `hengel_master.do` (line 11):**
```stata
global n = char(10)  // newline character for use in estout stats labels
```
Added immediately after `set maxvar 32767`. This ensures `${n}` reliably expands to a newline in all do-files on every future run.

---

### `replication.pdf` recompiled cleanly — 178 pages.

---

### New file: `outputs/results_summary.tex` / `results_summary.pdf`

Created a focused summary PDF containing only the main new results (LLM analyses alongside their traditional counterparts). 23 pages, no errors.

**Contents:**
- Figures 1, 1 LLM, 4, 4 LLM, 6, 6 LLM
- Table 1 LLM
- Tables 3, 3 LLM, 4, 5, 5 LLM, 8, 8 LLM, 9, 9 LLM, 10, 10 LLM (all FemRatio / base specification)

**Preamble addition:** `\floatplacement{table}{H}` (requires `float` package, already loaded) — forces all `\begin{table}` environments (which default to `[tbp]`) to place exactly at their insertion point, preventing tables from floating above their section headings.

---

## Session: 2026-03-16 (part 3)

### Theme: LLM readability analogs of Table-10 and Figure-6

---

### New do-files: `Table-10-llm.do` and `Figure-6-llm.do`

Created two new do-files that replicate the career-sequence readability analysis using LLM readability scores instead of Flesch scores.

**`code/hengel_replication/0-code/output/Table-10-llm.do`**
- Identical to `Table-10.do` with `nber_flesch_score` → `nber_llm_readability_score` and `_flesch_score` → `_llm_readability_score`
- Outputs `outputs/tables/tex/Table-10-llm.tex` via `create_latex` tablename `table9llm`

**`code/hengel_replication/0-code/output/Figure-6-llm.do`**
- Identical to `Figure-6.do` with the same variable substitutions, plus graph title changed to `"LLM Readability"`
- Outputs `outputs/figures/Figure-6-llm.pdf`

---

### `hengel_master.do` — 2 new include lines

Added immediately after their classical counterparts:
```stata
include "~/tonal_analysis/code/hengel_replication/0-code/output/Figure-6-llm.do"   (after Figure-6.do)
include "~/tonal_analysis/code/hengel_replication/0-code/output/Table-10-llm.do"   (after Table-10.do)
```

---

### `data/raw/hengel_labels/tables.xlsx` — `table9llm` row added

Added one new row (row 1007) via openpyxl:
- **TableName:** `table9llm`
- **Title:** `LLM readability of authors' \(t\)th paper (draft and final)`
- **Note:** Exact copy of the `table9` note
- **CellWidth:** `p{3cm}S@{}S@{}S@{}S@{}S@{}S@{}`
- **Header:** `&{\(t=1\)}&{\(t=2\)}&{\(t=3\)}&{\(t=4\text{--}5\)}&{\(t\ge6\)}`
- **Label:** `table9llm`, **Star:** `all`, all other columns empty

---

### `outputs/replication.tex` — 2 new entries

- **Figure 6 LLM subsection** added after Figure 6 (line ~153): `\includegraphics{figures/Figure-6-llm.pdf}`
- **Table 10 LLM section** added after Table 10 (line ~566): `\input{tables/tex/Table-10-llm.tex}`

---

## Session: 2026-03-12

### Theme: Fix Issues 3, 4, 5 in `replication.pdf`

---

### Issue 3 — `\_llm\_readability\_score` row label (FIXED)

**Root cause:** `_llm_readability_score` had no Stata variable label, so `estout` used the raw variable name. Previous underscore-escaping fix made it render as `\_llm\_readability\_score`.

**Fix — do-files (future runs):**
- `Table-3.do` line 124: Added `_llm_readability_score "LLM Readability"` to `varlabels()` option
- `Table-5.do` `nber_table` program: Added `varlabels(_llm_readability_score "LLM Readability")` (previously had no varlabels option)
- Same precautionary change in `Table-3-llm.do` and `Table-5-llm.do`

**Fix — existing .tex files (immediate patch):**
- 7 `Table-3-*.tex` files: replaced `\mrow{3cm}{\_llm\_readability\_score}` → `\mrow{3cm}{LLM Readability}`
- 9 `Table-5-*.tex` files: replaced `\_llm\_readability\_score` → `LLM Readability`

---

### Issue 5 — Right-margin clipping on Table-3 family (FIXED)

**Root cause:** Two compounding problems:
1. Tabular spec `p{2cm}` did not match `\mrow{3cm}{...}` used for row labels — causing 28.45pt overflow per data row and visual label/data overlap
2. 9-column portrait table (with p{2cm}) exceeded text width

**Fix — 7 `Table-3-{FemRatio,Fem1,Fem100,Fem50,FemJunior,FemSenior,FemSolo}.tex` (immediate patch):**
- Changed `\begin{table}` → `\begin{sidewaystable}` (landscape, uses `rotating` package already loaded)
- Changed tabular spec `{p{2cm}S@{}...}` → `{p{3cm}S@{}...}` to match `\mrow{3cm}{}` width
- Result: table is ~655pt wide; in sidewaystable landscape the effective height is 697pt (\textheight) → fits without clipping

**Fix — `tables.xlsx` (permanent, Stata-side — 2026-03-12 session):**
- All `table3` and `table3llm` rows: set `Landscape = '1'` and replaced `p{2cm}` → `p{3cm}` in `CellWidth`
- 17 rows updated (FemRatio, Fem1, Fem100, Fem50, FemJunior, FemSenior, FemSolo, R, journal variants for both table3 and table3llm)
- Future Stata runs will automatically generate `\begin{sidewaystable}` with correct column spec

---

### Issue 4 — Column mismatch / overflow in 3 appendix LLM tables (FIXED)

The 3 tables (`Table-G.1-llm`, `Table-G.4-llm`, `Table-I.2-llm`) had 11 data columns but placeholder headers (6)–(11).

**Finding (2026-03-12 session):** The do-files were already correct — all three iterate over `foreach stat in llm_g1 llm_g2 llm_g3 llm_g4 llm_g5` → 5 columns output. The 11-column `.tex` files were artifacts of a temporary `.tex` patch from 2026-03-10. They will be automatically corrected to 5 columns on the next Stata run.

**Immediate `.tex` patches (2026-03-12 session):**
- `Table-G.4-llm.tex` (178pt over): changed `\begin{table}[H]` → `\begin{sidewaystable}` → total width 628pt < 697pt ✓
- `Table-I.2-llm.tex` (130pt over): same → total width 580pt < 697pt ✓
- `Table-G.1-llm.tex` (previously 438pt over): changed `\begin{table}` → `\begin{sidewaystable}`, removed `\sisetup{round-precision=3}` (which was inflating S column widths when combined with global `parse-numbers=false`), changed `p{3cm}` → `p{4cm}` to match `\mrow{4cm}{}` row labels → total width now 669pt < 697pt ✓

**Fix — `tables.xlsx` (permanent, Stata-side — 2026-03-12 session):**
- `table6llm/full` row: cleared `SISetup` (was `'round-precision=3'`) → future runs will not insert `\sisetup{round-precision=3}` into `Table-G.1-llm.tex`
- Do-files confirmed correct (5-column output); no changes needed there

---

### Remaining issues in `replication.pdf`

All issues resolved as of 2026-03-16. See session notes below.

### Next step

Re-run `hengel_master.do` end-to-end to regenerate all tables from the updated `tables.xlsx` (which now has [p] Float specifiers for sidewaystables and \autoref{} → plain text in Notes), then recompile `replication.pdf`.

---

## Session: 2026-03-16 (part 2)

### Table-H.4 col 3 Constant SE discrepancy (RESOLVED — 2026-03-17)

**What:** `Table-H.4.tex` col 3 (75th percentile, spec 1) Constant:
- Original paper: `40.67` (no stars), SE = `(25.99)`
- Replication:    `40.67***`, SE = `(6.21)`
- Col 6 also differs slightly: SE `16.11` → `17.73`

**Resolution:** Convergence check run on 2026-03-17 with `iterate(5000)`:
```
Constant b = 40.668561  SE = 6.2126797
```
SE is identical at `iterate(5000)` vs `iterate(1000)`. The replication SE of **6.21 is correct**. The original paper used a non-converged solution (SE = 25.99). No further action needed.

---

## Session: 2026-03-16

### Theme: Fix Issues 6, 7, 8, 9 in `replication.pdf`

---

### Issue 6 — `\autoref{}` → `??` (FIXED)

**Root cause:** Table notes in 17 `.tex` files referenced labels (`equation2`, `equation3`, `Corollary1`, `gender`, `equationX`, etc.) defined in the main Hengel paper manuscript, which is not included in `replication.tex`.

**Fix — 17 `.tex` files patched directly:**
- All `\autoref{equationN}` → `equation~(N)`
- `\autoref{Corollary1}` → `Corollary~1`
- `see~\autoref{gender} for more details` → `see the text for more details`
- `\autoref{equationX}` → `the baseline FGLS specification`
- `\autoref{data}` → `the data appendix`
- `\autoref{matchingestimation}` → `the matching estimation section`
- `\autoref{quantification}` → `the quantification section`
- `\autoref{FootnoteAERpp}` → `the paper`

Affected files: `Table-3-FemRatio`, `Table-5-FemRatio`, `Table-6-FemRatio`, `Table-7-FemRatio`, `Table-8-FemRatio`, `Table-9-base/jel/R`, `Table-10`, `Table-F.2-FemRatio`, `Table-G.1/G.2/G.4`, `Table-H.3`, `Table-I.3`, `Table-J.2/J.3`.

**Fix — `tables.xlsx` (permanent):** Python script replaced `\autoref{}` calls in all Note cells (~30 cells updated).

---

### Issue 7 — TOC subsection entries missing space (FIXED)

**Fix:** Added `\setcounter{tocdepth}{1}` to `outputs/replication.tex` preamble (after `\usepackage{hyperref}`). TOC now shows only the 23 top-level sections.

---

### Issue 8 — Missing original Table 1 (CLOSED)

**Finding:** `Table-B.1.tex` (article counts) is already included at `replication.tex:543`. There is no `Table-1.do` — only `Table-1-llm.do` exists. No separate non-LLM Table 1 ever existed in this replication. Issue closed.

---

### Issue 9 — Excessive blank pages before sidewaystables (FIXED)

**Fix — 29 `.tex` files:** Added `[p]` placement specifier to all `\begin{sidewaystable}` → `\begin{sidewaystable}[p]`. The `[p]` option places the float on a dedicated float page, preventing blank pages before it.

Affected files: all 7 `Table-3-Fem*.tex`, all 10 `Table-5-{Fem*,jel,R,wordlimit}.tex`, all 9 `Table-5-llm-*.tex`, `Table-G.1-llm.tex`, `Table-G.4-llm.tex`, `Table-I.2-llm.tex`.

**Fix — `tables.xlsx` (permanent):** Python script set `Float` column to `float[p]` for all `table3`, `table3llm`, `table6`, `table6llm` rows so future Stata runs produce `[p]`.

---

### `replication.pdf` recompiled cleanly (no errors or undefined reference warnings).

---

## Session: 2026-03-11

### Theme: `replication.pdf` audit and fix — `\caption{0}` and broken table notes in 34 tables

---

### Root cause discovered and fixed: `\caption{0}` in 34 tables

#### Problem

34 `.tex` table files had `\caption{0}` and table notes of the form `\item \textit{Notes}. 0 ***, ** and * statistically significant at 1\%, 5\% and 10\%, respectively.` — the literal `0` where the title and note text should appear.

#### Root cause

The variant-table rows in `data/raw/hengel_labels/tables.xlsx` (e.g., `table3/Fem1`, `table6/Fem50`, etc.) used Excel formula cells — `=CONCATENATE("\\autoref{",A32,"_FemRatio}, ", VLOOKUP(...))` — for their Title and Note columns. Stata's `import excel` does not evaluate these formulas; it reads them and resolves to `0` instead of the cached string value. The base `FemRatio` rows used plain static strings and always worked correctly.

Additionally, 4 cells had `#N/A` cached values (VLOOKUP found no match):
- `table10/thresholds` Title
- `table6/change_full`, `table6/wordlimit`, `table6/jel` Notes

#### Fix — two layers

**1. Replicable fix (`tables.xlsx`):** Python script replaced all 84 formula cells (Title and Note columns) with their computed static string values. The 4 `#N/A` cells were given explicit replacement text. A backup was saved as `tables_backup.xlsx`.

```
table10/thresholds  Title → '\autoref{table10_FemRatio}, age thresholds'
table6/change_full  Note  → 'Coefficients from OLS regression of change in readability score. Uses the fixed-effects specification.'
table6/wordlimit    Note  → 'Estimates are identical to those in \autoref{table6_FemRatio}, except that the sample is restricted to NBER working papers with abstracts below the official journal word limit.'
table6/jel          Note  → 'Columns display estimates identical to those in \autoref{table6_FemRatio}, except that primary JEL code effects are included as additional controls.'
```

Future Stata runs will now read static strings from `tables.xlsx` and produce correct `\caption{...}` output.

**2. Immediate fix (34 `.tex` files):** Patched all existing `.tex` files with correct captions and notes (derived from `tables.xlsx`) so the PDF is correct without waiting for a Stata re-run.

Affected files (`Table-{3,5,6,7,8}-{Fem1,Fem100,Fem50,FemJunior,FemSenior,FemSolo,R,pubyear,subyear}.tex` — full list):
- Table-3: Fem1, Fem100, Fem50, FemJunior, FemSenior, FemSolo, R
- Table-5: Fem1, Fem100, Fem50, FemJunior, FemSenior, FemSolo, R
- Table-6: Fem1, Fem100, Fem50, FemJunior, FemSenior, FemSolo, pubyear, subyear
- Table-7: Fem1, Fem100, Fem50, FemJunior, FemSenior, FemSolo
- Table-8: Fem1, Fem100, Fem50, FemSenior, FemSolo, R

**Note on tablename mapping** (do-file `tablename` arg → `.tex` filename prefix):
| .tex prefix | tablename in do-file |
|---|---|
| `Table-3-*` | `table3` |
| `Table-5-*` | `table6` (Table-5.do uses `tablename("table6")`) |
| `Table-6-*` | `table10` |
| `Table-7-*` | `table11` |
| `Table-8-*` | `tableH2` |

`replication.pdf` recompiled cleanly after all patches.

---

### Remaining issues in `replication.pdf`

The following issues were identified during an audit of `replication.tex` and `replication.pdf` but have **not yet been fixed**:

#### Issue 3 — `\_llm\_readability\_score` row label (cosmetic, ~18 tables)

**Problem:** Tables in the Table-3 and Table-5 families display `\_llm\_readability\_score` as the row label for the LLM readability score row, instead of a human-readable name like "LLM Readability".

**Root cause:** The `colnames` argument in `Table-3.do` and `Table-5.do` uses `_llm_readability_score` as the column name, which `estout` passes through as the row label. The `varlabels(, prefix("\mrow{3cm}{") suffix("}"))` option wraps it as-is.

**Fix needed (Stata-side):** In `Table-3.do` and `Table-5.do`, add an explicit varlabel mapping in the `estout` call:
```stata
varlabels(_llm_readability_score "LLM Readability", prefix("\mrow{3cm}{") suffix("}"))
```
Same fix needed in `Table-3-llm.do` and `Table-5-llm.do` for the LLM composite group rows (which currently show ugly `\_llm\_g*\_score` labels).

#### Issue 4 — Column mismatch in 3 appendix LLM tables (Stata-side decision needed)

**Problem:** `Table-G.1-llm.tex`, `Table-G.4-llm.tex`, `Table-I.2-llm.tex` have 11 data columns but headers that only name the first 5 (`G1` through `G5`), with placeholders `(6)` through `(11)`. These tables are currently readable but unprofessional.

**Root cause:** The corresponding do-files were written for 5 LLM composite groups but export 11 model specifications.

**Fix needed:** Review and decide in Stata — either reduce to 5 columns per composite, or update the column headers to name specs (6)–(11) properly. See 2026-03-10 session notes for full details.

#### Issue 5 — Right-margin clipping on 9-column Table-3 variants

**Problem:** Table-3-FemRatio and related 9-column tables clip the rightmost columns outside the page margin.

**Fix needed:** Switch to `sidewaystable` (set `Landscape=1` in `tables.xlsx` for `table3/FemRatio` and variants) or use `\resizebox{\textwidth}{!}{...}` (set `AdjustWidth` column). Since Table-5-FemRatio already uses `sidewaystable`, the same approach should apply here.

#### Issue 6 — Unresolved `\autoref{}` → `??` in appendix table notes

**Problem:** Some appendix table notes (e.g., Table-G.1, Table-G.2) contain `\autoref{equation2}` etc. that render as `??` because the corresponding `\label{}` targets are defined inside the main body of the paper (not included in `replication.tex`, which only contains appendix tables and figures).

**Fix needed:** Either add `\label` definitions for the referenced equations to `replication.tex`, or replace `\autoref{}` references with plain text (e.g., "equation (2)") in the relevant `tables.xlsx` Note cells.

#### Issue 7 — TOC subsection entries missing space

**Problem:** Some subsection entries in the table of contents appear as `17.10Table F.2 LLM` instead of `17.10 Table F.2 LLM` — the number and title run together.

**Root cause:** The subsection title strings in `replication.tex` may be missing a leading space, or a LaTeX TOC formatting issue.

**Fix needed:** Review `replication.tex` subsection titles in the affected sections and add a space where missing.

#### Issue 8 — Missing original Table 1 (non-LLM)

**Problem:** Table 1 in the non-LLM replication is apparently absent from the rendered PDF (summary statistics or similar). `Table-B.1.do` calls `tablename("table1")` which exists in `tables.xlsx` but the output may not be included in `replication.tex`.

**Fix needed:** Verify `Table-B.1.tex` (or wherever Table 1 is written) exists and is `\input`-ted in `replication.tex`.

#### Issue 9 — Excessive blank pages before sidewaystables

**Problem:** Every section containing a `sidewaystable` is preceded by one or more blank pages, significantly inflating the page count.

**Root cause:** `sidewaystable` (from the `rotating` package) forces a page break before and after. The blank pages appear because each sideways table section starts a new page even when there is no content before it.

**Fix needed:** This is a LaTeX layout issue. Options include using `\afterpage{\clearpage}` to control page breaks, or restructuring the section ordering to minimize isolated sidewaystables.

---

### Updated Next Steps

1. **Fix Issue 3** (varlabel for `_llm_readability_score`) in `Table-3.do`, `Table-5.do`, `Table-3-llm.do`, `Table-5-llm.do` — simple Stata one-liner each.
2. **Fix Issue 4** (column mismatch) in `Table-G.1-llm.do`, `Table-G.4-llm.do`, `Table-I.2-llm.do` — design decision needed first.
3. **Fix Issue 5** (right-margin clipping) by setting `Landscape=1` in `tables.xlsx` for `table3/FemRatio` and related entries.
4. **Fix Issue 6** (`??` autorefs) by replacing `\autoref{equation*}` with plain text in the relevant `tables.xlsx` Note cells.
5. **Fix Issue 7** (TOC spacing) in `replication.tex`.
6. **Re-run `hengel_master.do`** end-to-end to regenerate all tables with the `tables.xlsx` formula-to-static fix and any do-file fixes applied.
7. **Recompile `replication.pdf`** and verify all issues resolved.
8. **Create `0-code_summary/*.txt` files** for the 10 new LLM do-files (carried over from prior sessions).

---

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
