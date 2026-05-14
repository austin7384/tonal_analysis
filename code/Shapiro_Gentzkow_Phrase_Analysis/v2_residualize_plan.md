# Plan: GST Phrase-Ranking v2 — Residualize Readability on Col. (5) Controls

## Context

v1 (`r_stage_plan.md`, completed 2026-05-13) produced
`outputs/tables/csv/sg_phrase_ranking_readability.csv`. Inspecting the top 30 by `|zeta|`
showed the ranking is partly stylistic but heavily contaminated by topic: high_read
markers like `house_prices`, `gender_gap`, `tax_returns`, `public_schools` are clearly
subject-matter, and low_read markers like `asymptotically_normal`, `unit_root`,
`regularity_conditions`, `infinite_horizon` are econometric-theory topic markers, not
prose-style markers.

v2 disentangles topic from style by residualizing Readability on the same control set
the main paper uses (slide 8 col. (5)), redefining top/bottom quintile on the residual,
and re-running the existing R DMR stage. ζ_j then reads as "phrase rate ratio between
high- and low-Readability abstracts *holding the col. (5) controls fixed*."

## Controls — slide 8 col. (5) — locked in for v2

From `Table-5-llm.do:33` (the saturated OLS spec used to produce the col. 5 numbers in
slides 8 and 10):

| Group              | Variables                                                   |
|--------------------|-------------------------------------------------------------|
| Journal × Year FE  | `i.Journal##i.Year` (absorbed)                              |
| Editor FE          | `i.Editor` (absorbed)                                       |
| Institution FE     | `i.MaxInst` (absorbed)                                      |
| Primary JEL        | `JEL1_*` dummies (absorbed)                                 |
| Theory/empirical   | `Type_*` dummies                                            |
| N_j                | `N` (number of authors)                                     |
| Quality controls   | `Maxt`, `MaxT`, `asinhCiteCount`                            |
| Native speaker     | `i.NativeEnglish`                                           |

Gender measures and the `Blind` interaction are intentionally **omitted** — those are
treatment variables in the main paper, not confounders for our v2 question. We want
"phrases that move with Readability holding topic / journal / quality / writer-fluency
constant," not "phrases that move with Readability holding gender constant."

## Approach

One Python script extension + one new R-stage invocation. No change to
`fit_phrase_lasso.R` is required.

### Stage 1a — residualize Readability (new step in Python)

Modify `code/Shapiro_Gentzkow_Phrase_Analysis/build_phrase_matrix.py`:

1. **After the existing Hengel-sample filter (journals + English + errata + dedupe +
   non-null Abstract/Readability),** join the col. (5) controls onto the dataframe.
   The merged article-level CSV may not carry `MaxInst`, `MaxT`, `Maxt`, `Editor`,
   `JEL1_*`, `Type_*`, or `NativeEnglish` — these likely need to be pulled from
   `data/processed/hengel_replication/` SQLite or from the Stata-built dataset that
   feeds `Table-5-llm.do`. Verify availability at the top of the script and hard-fail
   with a clear message if any control is missing.

2. **Fit OLS:**
   ```
   Readability ~ C(Journal):C(Year) + C(Editor) + C(MaxInst) + JEL1_* + Type_*
                 + N + Maxt + MaxT + asinhCiteCount + C(NativeEnglish)
   ```
   Use `statsmodels.OLS` with patsy-built design matrix (or `pyfixest.feols` if
   already available — pyfixest handles absorbed FE without expanding to a dense
   dummy matrix). The dense path is fine at N≈6,700 with ~500–800 dummy columns;
   memory ~50 MB.

3. **Take residuals** as `Readability_resid` and overwrite the existing score column
   used downstream. Drop the raw `Readability` from staging output to avoid confusion.

4. **Quintile cut on residuals** instead of raw score — same 20/80 logic as v1, just
   on `Readability_resid`. Expect a slightly different N per group than v1 (3,635 /
   3,069) because residualization redistributes mass; note actual counts in the
   script's `print()` output.

### Stage 1b — write staging files to a separate directory

Output to `data/processed/sg_phrase_analysis_residualized/` (new directory) with the
same three CSVs (`documents.csv`, `phrases.csv`, `phrase_counts.csv`). Adding a
column `Readability_resid` to `documents.csv` alongside the existing `Readability`
column is acceptable and useful for diagnostics, but `group` must be derived from
the residual.

Keeping v1's staging files untouched means the v1 CSV ranking stays reproducible
and the two outputs sit side-by-side for comparison.

### Stage 2 — re-run the R DMR stage on the new staging files

`fit_phrase_lasso.R` currently hardcodes
`IN_DIR <- file.path(ROOT, "data/processed/sg_phrase_analysis")` and
`OUT_FILE <- ".../sg_phrase_ranking_readability.csv"`.

Smallest change: parameterize both via an environment variable or an `Rscript` CLI
argument (e.g. `--variant residualized` toggles both paths). Cleanest change: keep
`fit_phrase_lasso.R` v1-only and add `fit_phrase_lasso_residualized.R` that differs
only in the two path constants. Either is fine — pick whichever fits the repo's
single-purpose-script convention better. (Project convention skews toward
single-purpose; lean that way.)

Output: `outputs/tables/csv/sg_phrase_ranking_readability_residualized.csv`, same
schema as v1.

## Output schema

`outputs/tables/csv/sg_phrase_ranking_readability_residualized.csv` — same six columns
as v1 (`phrase_idx, phrase, n_docs, total_count, zeta, direction`), sorted by
`-abs(zeta)`. No schema change, so any downstream diagnostic / plotting code that
reads v1 will read v2 unchanged.

## Critical files referenced

- **To modify:** `code/Shapiro_Gentzkow_Phrase_Analysis/build_phrase_matrix.py`.
- **To add:** `code/Shapiro_Gentzkow_Phrase_Analysis/fit_phrase_lasso_residualized.R`
  (twin of `fit_phrase_lasso.R` with different paths).
- **Source of col. (5) controls:** the Stata pipeline feeding `Table-5-llm.do:33`.
  Trace through `hengel_master.do` → `Data.do` to find the article-level dataset
  that carries `MaxInst`, `MaxT`, `Editor`, `JEL1_*`, `Type_*`, `NativeEnglish`,
  `Maxt`, `asinhCiteCount`, `N`. Export that to CSV once if not already available.
- **R script (unchanged):** `code/Shapiro_Gentzkow_Phrase_Analysis/fit_phrase_lasso.R`.

## Verification

1. **Control availability:** every variable in the col. (5) list resolves on the
   joined dataframe before fitting. Hard-fail otherwise.
2. **R²-style sanity:** OLS residualization should produce R² in roughly the
   0.15–0.35 range — substantial topic variance, but most readability variance is
   still abstract-specific. Print R² in `build_phrase_matrix.py` output.
3. **Quintile sizes:** print top vs bottom quintile N. Expect ≈ 1,300–1,400 per
   group (vs v1's 3,635 / 3,069) since we lose the asymmetry but keep ~20% per tail.
4. **DMR runs unchanged:** dim should still be roughly (n_top + n_bottom) × ~9,000.
   The DMR fit completes in similar wall time (≈ 90s).
5. **Top-30 diagnostic — the actual point of v2:** open the new CSV and compare its
   top 30 to v1's. The honest test: do econometric-jargon and topic-area phrases
   *demote* in the new ranking, and do hedges / connectives / qualifiers / voice
   markers *rise*? If yes, controls are doing real work. If the top 30 are
   essentially identical to v1, the controls are weak and we need to either
   include stronger topic controls (LDA topics, abstract length, etc.) or accept
   that the LLM rubric is topic-coupled by construction.
6. **Round-trip:** `sum(total_count)` matches between `phrases.csv` and the output
   ranking, same as v1.

## Robustness — deferred to v3

The col. (5) decision is for v2 only. v3 should run the same pipeline with:

- **Col. (4) controls** (drop quality controls, native speaker, JEL, theory/emp.) —
  isolates the contribution of those four blocks vs. the journal/year/editor/inst
  baseline.
- **Col. (5) + tertiary JEL** (`JEL3_*`) — heavier topic absorption.
- **Optional: LDA-topic controls instead of JEL** — JEL codes are coarse; an
  empirically-derived topic model may absorb more residual topic structure.

Each variant produces a new `sg_phrase_ranking_readability_<variant>.csv`. The set
of rankings, side-by-side, is the v3 deliverable.

## Out of scope (deferred again)

- Permutation test for null-distribution validation.
- Decile / tertile robustness on the residualized score.
- Additional LLM criteria beyond Readability.
- Unigrams.
- LaTeX table generation (CSV-only through v3).
