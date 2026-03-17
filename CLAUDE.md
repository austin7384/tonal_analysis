# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

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

**`code/LLM_evaluations/`** — OpenAI batch API wrapper. `run_evaluations.py` chunks abstracts in batches of 1000 and polls for completion. `clean_evaluations.py` parses raw LLM JSON into 16 numeric rubric columns. The rubric is defined in `helper_scripts/rubric.py`; the model and system prompt are in `helper_scripts/src/config.py` and `helper_scripts/src/prompt.py`.

**`code/gender_guess/`** — Namsor API client. Deduplicates names before calling the API, batches 100 names per request, then maps results back. `create_gender_index.py` aggregates to paper-level metrics (female authorship ratio, binary indicators, etc.).

**`code/hengel_replication/`** — Exports relational tables from CSV sources (`hengel_data_cleaning.py`), then performs analysis of derived variables in Stata (`hengel_master.do`). Descriptions of individual analysis files stored in `0-code_summary/`.

### LLM rubric
***Never alter or change the System Prompt or Rubric without explicit permission***

16 criteria scored 1–10 on surface-level linguistic features only (no author intent inference). Dimensions: modal verb strength, hedging, qualifier density, limitations acknowledgement, assertiveness, voice, sentence directness, novelty-claim strength, jargon density, emotional valence, evidence usage, practical orientation, readability.

The 16 criteria are grouped into five sections:
| Group | Criteria |
|---|---|
| G1 Creativity & Hedging | modal_verb, hedging, qualifier, ack_limits, caution |
| G2 Assertiveness & Voice | assertiveness, active_passive |
| G3 Structural Directness | directness, imperative |
| G4 Authorial Stance & Novelty | pronoun, novelty, jargon, emotional |
| G5 Support & Impact | evidence, practical |

`Jargon/Technicality Density` is scale-flipped (`11 - value`) in `hengel_data_cleaning.py` before computing the composite, keeping it on the 1–10 scale (raw 10 = dense jargon → stored as 1). NBER versions are prefixed `nber_llm_g*_score`. All composites end in `_score` so they are captured by the existing `reshape long @_score` in the `nber_fe` paired-difference dataset.

### Stata variable naming conventions for LLM criteria
After `reshape wide` in `Data.do`, individual LLM criterion variables are named `_llm_<short>` (article-level) and `nber_llm_<short>` (NBER-level):
- `_llm_readability`, `_llm_modal_verb`, `_llm_hedging`, `_llm_qualifier`, `_llm_ack_limits`
- `_llm_caution`, `_llm_assertiveness`, `_llm_active_passive`, `_llm_directness`, `_llm_imperative`
- `_llm_pronoun`, `_llm_novelty`, `_llm_jargon`, `_llm_emotional`, `_llm_evidence`, `_llm_practical`

### Article ID conventions
- Hengel articles: original IDs from the SQLite database
- Scraped articles: IDs offset by +15,000 in `merge_datasets.py`

## Open Issues
- **Table-H.4 col 3 Constant SE discrepancy**: Replication SE = 6.21 (***), original = 25.99 (no stars). Coefficient (40.67), N, and Pseudo R² match. Likely cause: `qreg vce(robust) quantile(0.75) iterate(1000)` convergence. `Table-H.4.do` now includes a convergence check re-running with `iterate(5000)` — check the Stata log after the next full run to diagnose. See RECENT_CHANGES.md for details.

## Notes
- LLM outputs are non-deterministic; re-running evaluations will produce slightly different scores
- Articles with >10 authors are filtered out in the gender inference stage
- `data/processed/llm_evaluated/`, `author_level.csv`, `gender_guesses.csv`, and `scraped_results.csv` are git-ignored (large files)
- The `.db` SQLite files and `.jsonl` batch files are also git-ignored
- Do not drop data without explicit permission
