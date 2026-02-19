# Gender Composition and Scientific Writing Style in Economics

## Overview

This repository contains the data construction and text-analysis pipeline for a research project examining whether the gender composition of author teams is associated with systematic differences in academic writing style.

Using 9,684 articles published in the five leading journals in economics, as well as 3298 articles from Management Science, we analyze titles and abstracts using a 16-item rubric capturing clarity, technicality, evidentiary support, tone, and rhetorical structure.

This repository contains the full data collection and processing pipeline used to construct the dataset, as well as some simple summary statistics. It does not contain econometric analysis code, regression output, or final figures.

---

## Relationship to Hengel (2022)

This project builds directly on the dataset constructed in Hengel (2022), which documents gender differences in readability and peer-review standards in economics journals.

The original Hengel analysis focused primarily on readability metrics. In contrast, the present project extends the analysis along three dimensions:

**Multidimensional Writing Evaluation**
We introduce a 16-item rubric capturing clarity, technical density, evidentiary support, rhetorical structure, and tone.

**Tonal and Rhetorical Analysis**
We measure features such as assertiveness, hedging, emotional valence, novelty framing, and use of qualifiers—dimensions not evaluated in the original paper.

**Expanded Communication Measures**
We distinguish structural clarity (e.g., active voice, evidentiary citation) from affective or tonal dimensions, allowing a sharper separation between communication structure and expressive tone.

The Hengel replication dataset serves as a structured baseline dataset that we augment with new writing-style measures generated via LLM-based evaluation.

---

## Repository Structure

```
.
├── code
│   ├── LLM_evaluations
│   │   ├── batch.jsonl
│   │   ├── checking_evaluations.ipynb
│   │   ├── clean_evaluations.py
│   │   ├── helper_scripts
│   │   └── run_evaluations.py
│   ├── data_scraping
│   │   ├── doi_scraper.py
│   │   ├── parse_abstract.py
│   │   ├── parse_acceptance.py
│   │   └── scrape_master_script.py
│   ├── gender_guess
│   │   ├── create_gender_index.py
│   │   ├── data_cleaning.py
│   │   ├── gender_name_master.py
│   │   └── gender_guess_helper
│   └── data_summary.py
├── data
│   ├── processed
│   └── raw
├── outputs
│   ├── figures
│   └── tables
└── requirements.txt
```

---

## Data Sources

This repository uses two distinct data sources.

**Unit of analysis:** Article-level. Author-level data are aggregated to construct team-level measures.

### 1. Hengel Replication Data

**Source:** [erinhengel/readability](https://github.com/erinhengel/readability)

**Location:** `data/raw/hengel_replication_data/`

**Characteristics:**
- Pre-existing structured dataset
- Does not require scraping or gender inference
- Only requires Step 2 (LLM-Based Writing Evaluation) of the pipeline below
- Extended in this project with additional writing-style measures

This dataset is used to extend the original readability analysis toward multidimensional tonal and rhetorical analysis.

### 2. Newly Constructed Dataset

This dataset is constructed through:
- Web scraping of article metadata and abstracts
- LLM-based writing style evaluation
- Author-level gender inference and team composition construction

**Location:** `data/raw/links_to_scrape.csv`

**Execution pipeline:** Scraping → LLM Evaluation → Gender Inference

> Some steps require API access and may incur usage costs.

---

## Execution Pipeline

### 1. Data Scraping

**Location:** `code/data_scraping/`

**Entry point:** `scrape_master_script.py`

**Description:** Scrapes article metadata and abstracts, parses acceptance and publication information, and outputs structured article-level records.

**Required input:** A column containing article URLs

**Output:** `data/processed/scraped_results.csv`

### 2. LLM-Based Writing Evaluation

**Location:** `code/LLM_evaluations/`

**Scripts (run in order):**
1. `run_evaluations.py`
2. `clean_evaluations.py`

**Required columns:** `ArticleID`, `Abstract`

This stage uses the OpenAI API to evaluate abstracts using a structured 16-item rubric.

**Output:** Cleaned LLM evaluation dataset in `data/processed/`

### 3. Gender Inference

**Location:** `code/gender_guess/`

**Scripts (run in order):**
1. `data_cleaning.py`
2. `gender_name_master.py`
3. `create_gender_index.py`

**Required input:** Author name columns, article identifiers

**Output:** `author_level.csv`, `gender_guesses.csv`, team-level gender composition variables

### Other
`merge_datasets.py` merges the Hengel evaluations with the scraped evaluations.

`data_summary.py` provides summary statistics for cleaned and merged data. Tables and figures created here go to `outputs`.

`data_validation.py` provides basic data checks for the fully merged dataset.

All meant to be ran after the full execution pipeline.

---

## Environment Setup

**Python Version:** Python 3.10+ recommended.

**Install dependencies:**

```bash
pip install -r requirements.txt
```

**Required environment variable:** This project requires an OpenAI API key and a Namsor gender checker API key. Create a `.env` file in the project root:

```
OPENAI_API_KEY=your_key_here
NAMSOR_API_KEY=your_key_here
```

> The `.env` file should not be committed to version control.

---

## Data Availability

Due to file size constraints, full processed datasets are not included in this repository. To regenerate the newly constructed datasets, for the DOI link data:

1. Run scraping
2. Run LLM evaluation
3. Run gender inference

And for the Hengel (2022) data:
1. Run LLM evaluation

Then, merge the datasets.

**Note:** Scraping depends on continued website availability. LLM outputs may vary slightly across model versions. Gender inference depends on name database coverage and configuration.

> `data/processed/sample_processed_output.csv` contains the result of running the code pipeline for the first 100 articles of the scraped dataset. This data is ready for analysis.

---

## Reproducibility Notes

- LLM-based measures may vary slightly across API versions.
- Some steps require paid API access.
- The replication dataset from Hengel (2022) is used as structured input and extended with additional writing-style measures.

---

## Contact

For replication or data construction questions, please contact the project authors directly.
