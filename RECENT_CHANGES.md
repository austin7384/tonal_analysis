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
