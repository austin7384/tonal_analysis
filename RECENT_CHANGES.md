# Recent Changes

## Session: 2026-02-26

### Problem
After `hengel_data_cleaning.py` was rewritten to include LLM evaluations alongside traditional Hengel readability stats in `article_pp.csv` and `nber.csv`, `Data.do` was broken. The LLM criterion names (e.g. `"Modal Verb Strength"`, `"Hedging Frequency & Type"`) contain spaces and special characters (`&`, `/`) that are invalid in Stata variable names. The `reshape wide` commands in `Data.do` would have failed with these stat names.

---

### Changes

#### `code/hengel_replication/hengel_data_cleaning.py`
- Added `LLM_RENAME` dictionary mapping all 15 space/symbol-containing LLM criterion names to Stata-compatible snake_case names with an `llm_` prefix:

| Original name | Renamed to |
|---|---|
| Modal Verb Strength | `llm_modal_verb` |
| Hedging Frequency & Type | `llm_hedging` |
| Qualifier Density | `llm_qualifier` |
| Acknowledgement of Limitations | `llm_ack_limits` |
| Caution-Signaling Connectors | `llm_caution` |
| Assertiveness & Voice | `llm_assertiveness` |
| Active/Passive Voice Ratio | `llm_active_passive` |
| Sentence Length & Directness | `llm_directness` |
| Imperative-Form Occurrence | `llm_imperative` |
| Pronoun Commitment | `llm_pronoun` |
| Novelty-Claim Strength | `llm_novelty` |
| Jargon/Technicality Density | `llm_jargon` |
| Emotional Valence | `llm_emotional` |
| Evidence & Citation Usage | `llm_evidence` |
| Practical/Impact Orientation | `llm_practical` |

  (`llm_readability` was already correctly named and is unchanged.)

- Applied the rename to both `llm_eval` and `nber_llm` DataFrames before melting to long format, so the `StatName` column in `article_pp.csv` and `nber.csv` only contains valid Stata identifiers.
- Updated `LLM_NEGATE` from `{'Jargon/Technicality Density'}` to `{'llm_jargon'}` to match the renamed key (this controls sign-flipping in `compute_underscore`: jargon is negated so higher = less jargon = clearer).

#### `code/hengel_replication/0-code/output/Data.do`
- After the `reshape wide _` of `article_pp.csv`, added five LLM group composite scores for the published-abstract data:

```stata
generate _llm_g1_score = (_llm_modal_verb + _llm_hedging + _llm_qualifier + _llm_ack_limits + _llm_caution) / 5
generate _llm_g2_score = (_llm_assertiveness + _llm_active_passive) / 2
generate _llm_g3_score = (_llm_directness + _llm_imperative) / 2
generate _llm_g4_score = (_llm_pronoun + _llm_novelty + _llm_jargon + _llm_emotional) / 4
generate _llm_g5_score = (_llm_evidence + _llm_practical) / 2
```

- After the `reshape wide nber_` of `nber.csv` and merge with the article dataset, added the parallel NBER-abstract composites (`nber_llm_g1_score` through `nber_llm_g5_score`).

#### `data/raw/hengel_labels/varlabels.csv`
- Added variable label entries for all 16 individual LLM criterion variables (`_llm_readability`, `_llm_modal_verb`, …), the five group composite scores (`_llm_g1_score` through `_llm_g5_score`), and all `nber_` prefixed counterparts.

#### Regenerated CSVs
- `data/raw/hengel_generated/article_pp.csv` — stat names now Stata-friendly.
- `data/raw/hengel_generated/nber.csv` — stat names now Stata-friendly.

---

### Result

After these changes:

1. **`Data.do` runs without errors.** The `reshape wide` commands in the article-level P&P section and the NBER section now succeed because all `StatName` values are valid Stata identifiers.

2. **All saved Stata datasets include LLM variables.** Every dataset produced by `Data.do` (`article_pp`, `article`, `article_primary_jel`, `nber`, `nber_fe`, etc.) now contains:
   - 16 individual LLM criterion variables (e.g. `_llm_modal_verb`, `_llm_readability`)
   - 5 group composite scores (`_llm_g1_score` through `_llm_g5_score`)
   - NBER counterparts in the NBER/nber_fe datasets

3. **LLM group composites integrate with the existing `nber_fe` framework.** Because the group composite variable names end in `_score`, they are automatically captured by the existing `reshape long @_score` that builds the paired NBER-vs-published dataset. This means `D._llm_g1_score` (the change in Group 1 score from working paper to published version) is available without any additional code.

4. **Ready for LLM regression tables.** The five group composites follow the same `_<stat>_score` naming convention as the existing Hengel readability scores, so creating parallel LLM versions of Table-3 and Table-5 only requires passing `stats(llm_g1 llm_g2 llm_g3 llm_g4 llm_g5)` to the existing program definitions.

---

### Next Steps
- Create LLM-specific regression tables mirroring Table-3 (`article_level` program) and Table-5 (`nber_fgls`/`nber_fe` programs) using `stats(llm_g1 llm_g2 llm_g3 llm_g4 llm_g5)` and column names `_llm_g1_score _llm_g2_score _llm_g3_score _llm_g4_score _llm_g5_score`.

---

## Session: 2026-02-27

### Changes

#### `code/hengel_replication/0-code/output/Data.do`

**NBER per-group LLM datasets** — Added 15 new saved datasets (3 per group × 5 groups) after the existing `nber_fe_jel` block. For each LLM group G1–G5:
- `nber_llm_g{n}` — NBER data retaining only that group's individual NBER criteria, its NBER composite score (`nber_llm_g{n}_score`), and the matching article-level composite (`_llm_g{n}_score`, merged from `article_llm_full`). The article-level score is required so the FE paired-difference reshape can pair NBER vs. published group scores.
- `nber_llm_g{n}_fe` — Paired-difference version via the same double-reshape used for `nber_fe`.
- `nber_llm_g{n}_fe_jel` — FE version with primary JEL code dummies added.
- `nber_llm_g{n}_jel` (tempfile only) — `nber_llm_g{n}` + primary JEL; follows the existing `nber_jel` convention of not saving to disk.

No tertiary JEL variants were added, consistent with the existing NBER section (unlike the article section which has both primary and tertiary JEL variants).

**Duration variant datasets** — Added 6 new saved datasets immediately after the main `duration` dataset is saved. Each starts from the `duration` tempfile, drops `_flesch_score`, and merges in a replacement LLM readability measure:

| Dataset | Variable merged | Source |
|---|---|---|
| `duration_llm_readability` | `_llm_readability` | `article` tempfile |
| `duration_llm_g1` | `_llm_g1_score` | `article_llm_full` tempfile |
| `duration_llm_g2` | `_llm_g2_score` | `article_llm_full` tempfile |
| `duration_llm_g3` | `_llm_g3_score` | `article_llm_full` tempfile |
| `duration_llm_g4` | `_llm_g4_score` | `article_llm_full` tempfile |
| `duration_llm_g5` | `_llm_g5_score` | `article_llm_full` tempfile |

`_llm_readability` is sourced from `article` (it was never dropped from the main article datasets). The group composites are sourced from `article_llm_full` (they were dropped from `article` before it was saved).

#### `code/hengel_replication/hengel_data_cleaning.py` — Jargon scale flip

Changed how `llm_jargon` is transformed in `compute_underscore`. Previously it was simple negation (`-value`), which placed it on a negative scale incompatible with all other LLM criteria (scored 1–10). It is now scale-flipped as `11 - value`, keeping it on the same 1–10 range:

| Raw score | Before (negation) | After (flip) |
|---|---|---|
| 10 (densest jargon) | -10 | 1 |
| 5 | -5 | 6 |
| 1 (least jargon) | -1 | 10 |

Implementation details:
- Renamed `LLM_NEGATE` → `LLM_FLIP` to reflect the new semantics
- Split `compute_underscore` into two independent steps: Hengel negation (unchanged) and LLM scale flip (new), applied sequentially so they cannot interfere
- Updated inline comments and the sign-flip convention block

`CLAUDE.md` updated to reflect the flip rather than negation.

#### `code/hengel_replication/0-code_summary/` (new directory)

Created short `.txt` summary files for all 25 Stata `.do` files in `0-code/output/`. Each file documents the inputs, main operations, and outputs of the corresponding do-file. Two non-`.do` files were identified and skipped: `Figure-3.nb` and `Figure-G.2.nb` (Jupyter/Mathematica notebooks).

---

## Session: 2026-03-03

### Problems fixed

#### 1. `hengel_master.do` — `ssc install` failing with `r(602)`
`ssc install` refused to overwrite existing package files without permission. Fixed by adding `, replace` to all 10 `ssc install` calls.

#### 2. `hengel_master.do` — personal ado directory not found (`r(603)`)
The copy loop for custom Stata programs failed because `~/Documents/Stata/ado/personal/` did not exist. The entire approach was replaced: instead of copying files to the personal ado directory, `adopath +` is now used to add the project's `0-code/programs/stata/` directory directly to Stata's search path. Path uses tilde notation (`~/tonal_analysis/...`) consistent with all other paths in the codebase.

#### 3. `reghdfe` failing with `r(9)` — missing `require` package
Newer versions of `reghdfe` depend on the `require` package to check its own dependencies at runtime. Added `ssc install require, replace` to `hengel_master.do` immediately after `reghdfe`.

#### 4. `Table-7.do` — `r(2001)` insufficient observations for REStud regressions
Root cause: `CiteCount` was entirely missing for all REStud articles in the raw `Article.csv` (0/2,011 non-missing), so `asinhCiteCount` was missing for every RES observation, causing listwise deletion to drop all 1,812 RES articles before `reghdfe` ran.

Fix: patched `data/raw/hengel_replication_data/Article.csv` with REStud citation counts sourced from the matching dataset at `/Users/austincoffelt/readability/0-data/generated/time.csv` (identical ArticleIDs, complete RES data). 1,812 values filled in; the remaining 199 RES articles without citation data are articles that lack `Received` dates and therefore never appear in the duration dataset anyway. Regenerated `hengel_data_cleaning.py` to propagate the fix downstream.

#### 5. Figure export failing with `r(693)` — output directory missing
`graph export` for Figure-1 failed because `~/tonal_analysis/outputs/figures/` did not exist. Directory was created (implicitly, by running the analysis after the other fixes allowed execution to reach the figure export step).

---

### Changes

#### `code/hengel_replication/hengel_master.do`
- All `ssc install` calls now use `, replace`
- Added `ssc install require, replace` after `reghdfe`
- Replaced copy-to-personal-ado loop with: `adopath + "~/tonal_analysis/code/hengel_replication/0-code/programs/stata"`

#### `data/raw/hengel_replication_data/Article.csv`
- Filled in `CiteCount` for 1,812 REStud articles using citation data from `/Users/austincoffelt/readability/0-data/generated/time.csv`

#### `data/raw/hengel_generated/time.csv` (regenerated)
- Downstream of `Article.csv` patch; now has complete `CiteCount` for RES (3,085 rows, previously 0)

#### `outputs/replication.tex` (new file)
- Mega LaTeX document aggregating all output for Overleaf comparison
- Includes all 4 figures and all 44 table `.tex` files, organized by table number with subsections per gender specification
- Preamble defines custom macros `\mrow` and `\crcell` used throughout the Hengel tables
- References files via relative paths (`figures/` and `tables/tex/`) so the `outputs/` directory can be uploaded directly to Overleaf

---

### Current status of `hengel_master.do` run
The run reaches `Table-3.do` (article-level readability regressions) before stopping. All `Data.do` datasets are successfully generated. Figures 1, 2, and 4 complete. Tables 2, 3 (partial) produced.

---

### Remaining issues / next steps

#### A. Complete a clean full run of `hengel_master.do`
The run has not yet completed end-to-end. Each session has been stopped by a new error. Need a clean run that produces all outputs.

#### B. LLM regression tables (primary new analysis)
Still the main outstanding deliverable. Need to create do-files (or extend existing ones) that mirror:
- **Table-3** (`article_level` program) using `stats(llm_g1 llm_g2 llm_g3 llm_g4 llm_g5)` and column names `_llm_g1_score` through `_llm_g5_score`
- **Table-5** (`nber_fgls`/`nber_fe` programs) using the same LLM group composites
- **Table-7** (duration) using `duration_llm_g{n}` datasets

These datasets already exist in `data/raw/hengel_generated/`. The regression programs already exist and accept a `stats()` argument. Adding the LLM table calls to `hengel_master.do` is the main remaining coding task.

#### C. Verify `replication.tex` compiles cleanly in Overleaf
Upload `outputs/` to Overleaf and confirm all tables and figures render correctly. Known potential issues:
- `\autoref` cross-references point to labels in the original paper (e.g. `\autoref{gender}`) that don't exist in this standalone document — these will generate warnings but not compilation errors
- Some landscape tables may need `pdflscape` in addition to `rotating` if Overleaf's engine differs
