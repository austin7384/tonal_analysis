# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Always read RECENT_CHANGES.md first

At the start of every session, before reading any other code or planning work, read `RECENT_CHANGES.md` in the project root. It contains dated session entries describing what was done, key decisions, and open follow-ups. Use it to:

- Avoid redoing work that was already completed
- Pick up open follow-ups from the previous session
- Stay consistent with recent decisions (file conventions, build state, known issues)

If `RECENT_CHANGES.md` is missing, note it but do not block — proceed with the task.

## Setup

```bash
pip install -r requirements.txt
cp .env.example .env  # Add OPENAI_API_KEY and NAMSOR_API_KEY
```

## Pipeline Execution

Run scripts in this order. Each stage produces CSVs consumed by the next.

### New dataset (scraped articles)
```bash
python code/data_scraping/scrape_master_script.py
python code/LLM_evaluations/run_evaluations.py
python code/LLM_evaluations/clean_evaluations.py
python code/gender_guess/data_cleaning.py
python code/gender_guess/gender_name_master.py
python code/gender_guess/create_gender_index.py
```

### Hengel (2022) replication dataset
```bash
python code/LLM_evaluations/run_evaluations.py
python code/LLM_evaluations/clean_evaluations.py
python code/hengel_replication/hengel_data_cleaning.py
```
Analysis code/hengel_replication/hengel_master.do in Stata

### Post-pipeline
```bash
python code/data_summary.py      # outputs/tables/
python code/data_validation.py   # basic quality checks
```

### Standalone analysis (run after hengel_master.do)
```bash
python code/LLM_evaluations/correlation_matrix.py   # outputs/tables/tex/Table-Corr.tex
python code/LLM_evaluations/llm_summary_stats.py    # outputs/tables/tex/Table-LLM-Summary.tex
python code/hengel_replication/summary_table.py     # outputs/tables/tex/Table-S.1.tex
python code/hengel_replication/compare_tables.py    # outputs/table_comparison_report.md (diagnostic)
```

## Architecture

### Data Flow
```
links_to_scrape.csv
  → [scrape_master_script.py] → scraped_results.csv
  → [data_cleaning.py] → author_level.csv
  → [run_evaluations.py + clean_evaluations.py] → llm_evaluated/clean_evaluations/
  → [gender_name_master.py] → gender_guesses.csv
  → [create_gender_index.py] → paper-level gender composition columns
  → [merge_datasets.py] → merged_evaluations.csv
  → [data_summary.py] → outputs/tables/
```

### Key modules

**`code/data_scraping/`** — Selenium+BeautifulSoup scraper. One Chrome browser per DOI, 60-second backoff on rate limits. `parse_abstract.py` strips INFORMS boilerplate; `parse_acceptance.py` extracts editor name/department via regex.

**`code/LLM_evaluations/`** — OpenAI batch API wrapper. `run_evaluations.py` chunks abstracts in batches of 1000 and polls for completion. `clean_evaluations.py` parses raw LLM JSON into 16 numeric rubric columns. The rubric is defined in `helper_scripts/rubric.py`; the model and system prompt are in `helper_scripts/src/config.py` and `helper_scripts/src/prompt.py`. `correlation_matrix.py` computes a 16×16 Pearson correlation matrix of LLM tonal criteria and outputs `Table-Corr.tex`. `llm_summary_stats.py` produces summary statistics by gender composition and journal, outputting `Table-LLM-Summary.tex` and three CSVs (`llm_summary_overall.csv`, `llm_summary_by_gender.csv`, `llm_summary_by_journal.csv`).

**`code/gender_guess/`** — Namsor API client. Deduplicates names before calling the API, batches 100 names per request, then maps results back. `create_gender_index.py` aggregates to paper-level metrics (female authorship ratio, binary indicators, etc.).

**`code/hengel_replication/`** — Exports relational tables from CSV sources (`hengel_data_cleaning.py`), then performs analysis of derived variables in Stata (`hengel_master.do`). Descriptions of individual analysis files stored in `0-code_summary/`. `summary_table.py` generates `Table-S.1.tex` (article and NBER working paper counts by journal) directly from the SQLite database. `compare_tables.py` is a diagnostic tool that validates replication `.tex` tables against originals with tolerance-based matching, outputting `outputs/table_comparison_report.md`.

### LLM rubric
***Never alter or change the System Prompt or Rubric without explicit permission***

16 criteria scored 1–10 on surface-level linguistic features only (no author intent inference). Dimensions: modal verb strength, hedging, qualifier density, limitations acknowledgement, assertiveness, voice, sentence directness, novelty-claim strength, jargon density, emotional valence, evidence usage, practical orientation, readability.

The 16 criteria are grouped into five sections:
| Group | Criteria |
|---|---|
| G1 Creativity & Hedging | modal_verb, hedging, qualifier, ack_limits, caution |
| G2 Assertiveness & Voice | assertiveness, active_passive |
| G3 Structural Directness | directness, imperative† |
| G4 Authorial Stance & Novelty | pronoun, novelty, jargon, emotional |
| G5 Support & Impact | evidence, practical |

†`imperative` has zero variance in the FemSolo subsample (all solo-authored NBER papers score 1), causing `suest` to fail with r(322). It is excluded from the individual-criteria tables; G3 in those tables contains only `directness`.

`Jargon/Technicality Density` is scale-flipped (`11 - value`) in `hengel_data_cleaning.py` before computing the composite, keeping it on the 1–10 scale (raw 10 = dense jargon → stored as 1). NBER versions are prefixed `nber_llm_g*_score`. All composites end in `_score` so they are captured by the existing `reshape long @_score` in the `nber_fe` paired-difference dataset.

### Stata variable naming conventions for LLM criteria
After `reshape wide` in `Data.do`, individual LLM criterion variables are named `_llm_<short>` (article-level) and `nber_llm_<short>` (NBER-level):
- `_llm_readability`, `_llm_modal_verb`, `_llm_hedging`, `_llm_qualifier`, `_llm_ack_limits`
- `_llm_caution`, `_llm_assertiveness`, `_llm_active_passive`, `_llm_directness`, `_llm_imperative`
- `_llm_pronoun`, `_llm_novelty`, `_llm_jargon`, `_llm_emotional`, `_llm_evidence`, `_llm_practical`

`Data.do` also generates `nber_llm_<short>_score` aliases for all 15 individual criteria (all except `imperative`) plus `nber_llm_readability_score`, so that `reshape long @_score` in the `nber_fe` paired-difference dataset captures individual criteria automatically alongside group composites.

### Individual LLM criteria tables

Two scripts produce tables breaking out all 16 individual LLM criteria across gender measures:

**`code/hengel_replication/0-code/output/Table-3-llm-individual.do`** — NBER paired-difference design (analogue of Table 3). Gender measures: FemRatio, Fem1, Fem50, Fem100, FemSolo, FemSenior. Output per variant: two landscape sidewaystables:
- Part 1 (`tablename="table3llmind1"`): modal_verb, hedging, qualifier, ack_limits, caution, assertiveness, active_passive, directness (G1–G3, imperative excluded)
- Part 2 (`tablename="table3llmind2"`): pronoun, novelty, jargon, emotional, evidence, practical, readability (G4–G5 + Readability)

**`code/hengel_replication/0-code/output/Table-5-llm-individual.do`** — Author-level design (analogue of Table 5). 9 variants: above 6 + FemJunior, jel, wordlimit. Same two-sub-table split (`tablename="table6llmind1"` and `"table6llmind2"`).

Both scripts define `nber_fe` and `nber_fgls` internally and can run standalone without their parent Table-3/5 `.do` active. They add a `firststats(string)` option to `nber_fgls` to avoid hardcoded `estimates restore` calls.

**Post-processing note:** `estout`'s `varlabels` option strips one backslash, so group-header rows in generated `.tex` files end with `\` instead of `\\`. A Python post-processing step must append the missing backslash to all lines matching `\textbf{G...}` or `\textbf{Standalone}` before LaTeX compilation. This is documented in comments inside both do-files.

### Article ID conventions
- Hengel articles: original IDs from the SQLite database
- Scraped articles: IDs offset by +15,000 in `merge_datasets.py`

## Open Issues
- **`imperative` zero variance in FemSolo**: Imperative-Form Occurrence scores all 1 for solo-authored NBER papers. Excluded from individual-criteria tables (Table-3-llm-individual.do, Table-5-llm-individual.do). Data characteristic, not a code bug.
- **Table-H.4 col 3 Constant SE discrepancy**: Replication SE = 6.21 (***), original = 25.99 (no stars). Coefficient (40.67), N, and Pseudo R² match. Likely cause: `qreg vce(robust) quantile(0.75) iterate(1000)` convergence. `Table-H.4.do` now includes a convergence check re-running with `iterate(5000)` — check the Stata log after the next full run to diagnose. See RECENT_CHANGES.md for details.

## Selectively running scripts in hengel_master.do

`hengel_master.do` contains `include` statements for every output script. To control which scripts run, comment out unwanted lines with `*` — never delete them. `Data.do` must always remain active as it builds all datasets used downstream.

Example — to run only Figure 6 variants:
```stata
* Run analyses.
*include ".../Figure-1.do"
*include ".../Figure-1-llm.do"
*include ".../Figure-1-llm-g4.do"
...
include ".../Figure-6.do"
include ".../Figure-6-llm.do"
include ".../Figure-6-llm-g3.do"
*include ".../Table-10.do"
...
```

To restore a full run, remove all leading `*` from the `include` lines.

## Outputs
- `outputs/replication.pdf` — full replication document with all tables, figures, and appendices
- `outputs/results_summary.pdf` — streamlined summary containing only main-specification (FemRatio/base) results for key figures and tables; compiled from `outputs/results_summary.tex`

## Notes
- LLM outputs are non-deterministic; re-running evaluations will produce slightly different scores
- Articles with >10 authors are filtered out in the gender inference stage
- Main analysis sample: N=9,117 article-level observations (after English-language filter, errata filter, and exclusion of 4 ECA articles identified post-merge). Applied consistently in both the Stata pipeline and standalone Python analysis scripts.
- `data/processed/llm_evaluated/`, `author_level.csv`, `gender_guesses.csv`, and `scraped_results.csv` are git-ignored (large files)
- The `.db` SQLite files and `.jsonl` batch files are also git-ignored
- Do not drop data without explicit permission
