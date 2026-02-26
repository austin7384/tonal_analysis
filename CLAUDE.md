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
python code/hengel_replication/hengel_data_cleaning.py  # exports SQLite → CSV
# Run code/hengel_replication/hengel_master.do in Stata
python code/LLM_evaluations/run_evaluations.py          # LLM eval only
python code/LLM_evaluations/clean_evaluations.py
```

### Post-pipeline
```bash
python code/merge_datasets.py    # merges Hengel + scraped → merged_evaluations.csv
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

**`code/hengel_replication/`** — Exports 12 relational tables from a SQLite `.db` to CSV (`hengel_data_cleaning.py`), then constructs derived variables in Stata (`hengel_master.do`).

**`code/merge_datasets.py`** — Combines Hengel and scraped datasets. Offsets scraped `ArticleID` by 15,000 to avoid collisions, standardizes column names, tags journal source.

### LLM rubric
16 criteria scored 1–10 on surface-level linguistic features only (no author intent inference). Dimensions: modal verb strength, hedging, qualifier density, limitations acknowledgement, assertiveness, voice, sentence directness, novelty-claim strength, jargon density, emotional valence, evidence usage, practical orientation, readability.

### Article ID conventions
- Hengel articles: original IDs from the SQLite database
- Scraped articles: IDs offset by +15,000 in `merge_datasets.py`

## Notes
- LLM outputs are non-deterministic; re-running evaluations will produce slightly different scores
- Articles with >10 authors are filtered out in the gender inference stage
- `data/processed/llm_evaluated/`, `author_level.csv`, `gender_guesses.csv`, and `scraped_results.csv` are git-ignored (large files)
- The `.db` SQLite files and `.jsonl` batch files are also git-ignored
