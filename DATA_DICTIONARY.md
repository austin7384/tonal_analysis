# Project Data Dictionary

## Dataset Overview

This project integrates multiple data sources:

1. Replication database from the Hengel paper (relational structure)
2. Scraped journal metadata
3. Gender inference outputs (Namsor-based)
4. LLM writing-style evaluations
5. Constructed authorship composition variables

**Primary unit of analysis (final dataset): Article-level**

Secondary units:
- Author-level
- Institution-level
- Working paper-level (NBER)

Many-to-many relationships are defined via correspondence tables.

---

# PART I — HENGEL REPLICATION DATABASE

**Location:** `data/raw/hengel_replication_data/`

## Table: Article

| Variable | Type | Description |
|-----------|--------|-------------|
| ArticleID | String | Unique identifier for each article (Primary Key) |
| Journal | Categorical | Journal of publication (AER, ECA, JPE, QJE, RES, P&P) |
| PubDate | Date | Publication date (YYYY-MM-DD) |
| Title | String | Article title |
| Abstract | Text | Article abstract |
| Language | Categorical | Publication language (English, French) |
| Received | Date | First submission date (YYYY-MM-01) |
| Accepted | Date | Final acceptance date (YYYY-MM-01) |
| Volume | Integer | Journal volume |
| Issue | Integer | Journal issue |
| Part | Integer | Journal part |
| FirstPage | Integer | First page number |
| LastPage | Integer | Last page number |
| CiteCount | Integer | Citation count (Web of Science) |
| Note | String | Notes on observation |

---

## Table: Author

| Variable | Type | Description |
|-----------|--------|-------------|
| AuthorID | String | Unique author identifier |
| AuthorName | String | Author name |
| Sex | Categorical | Author gender |
| NativeLanguage | Categorical | English, Non-English, Unknown |

---

## Table: AuthorCorr

Mapping table between authors and articles.

| Variable | Description |
|-----------|-------------|
| AuthorID | Maps to Author table |
| ArticleID | Maps to Article table |

---

## Table: Children

| Variable | Description |
|-----------|-------------|
| AuthorID | Author identifier |
| Year | Year child was born |
| BirthOrder | Order if multiple children born in same year |

---

## Table: EditorBoard

| Variable | Description |
|-----------|-------------|
| AuthorID | Editor identifier |
| Journal | Journal |
| Volume | Volume |
| Issue | Issue |
| Part | Part |

---

## Table: Inst

| Variable | Description |
|-----------|-------------|
| InstID | Unique institution ID |
| InstName | Institution name |

---

## Table: InstCorr

Institution–Author–Article mapping.

| Variable | Description |
|-----------|-------------|
| InstID | Maps to Inst |
| ArticleID | Maps to Article |
| AuthorID | Maps to Author |

---

## Table: JEL

| Variable | Description |
|-----------|-------------|
| ArticleID | Article identifier |
| JEL | Tertiary JEL code |

---

## Table: NBER

| Variable | Description |
|-----------|-------------|
| NberID | Unique NBER working paper ID |
| WPDate | Working paper release date |
| Title | Working paper title |
| Abstract | Working paper abstract |
| Note | Notes on matching process |

---

## Table: NBERCorr

| Variable | Description |
|-----------|-------------|
| NberID | Maps to NBER |
| ArticleID | Maps to Article |

---

## Table: ReadStat

| Variable | Description |
|-----------|-------------|
| ArticleID | Article identifier |
| StatName | Statistic name (e.g., Flesch) |
| StatValue | Value of statistic |

---

## Table: NBERStat

| Variable | Description |
|-----------|-------------|
| NberID | Working paper identifier |
| StatName | Statistic name |
| StatValue | Statistic value |

---

# PART II — SCRAPED JOURNAL DATASET

Unit of observation: Article-level

| Variable         | Type    | Description                                     |
|------------------|---------|-------------------------------------------------|
| ArticleID        | Integer | Unique article identifier (added in processing) |
| link             | String  | DOI link                                        |
| title            | String  | Article title                                   |
| authors          | String  | Raw author string                               |
| metrics          | String  | Download and citation metrics                   |
| received         | Date    | Submission date                                 |
| accepted         | Date    | Acceptance date                                 |
| published_online | Date    | Online publication date                         |
| under_review     | Integer | Days under review                               |
| pub_year         | Integer | Publication year                                |
| pub_month        | Integer | Publication month                               |
| accepted_by      | String  | Handling editor (added by scraping)             |
| department       | String  | Department accepting paper (added by scraping)  |
| Abstract         | Text    | Article abstract (added by scraping)            |

---

# PART III — Gender Inference Variables

Gender inference performed using Namsor name-based classification.

| Variable           | Type | Description                                                                 |
|--------------------|--------|-----------------------------------------------------------------------------|
| gender_namsor      | Categorical | Inferred gender classification (equivalent to Sex in the Hengel (2022) data |
| gender_prob_namsor | Float (0–1) | Probability classification is correct                                       |

Note: These classifications are probabilistic and may contain measurement error. Only in scraped dataset.

---

# PART IV — Constructed Authorship Composition Variables

Derived from author-level gender classifications.

Unit: Article-level

| Variable                | Type        | Construction                                                         |
|-------------------------|-------------|----------------------------------------------------------------------|
| total_authors           | Integer     | Number of authors on the article                                     |
| Female_authorship_ratio | Float (0–1) | Female authors / total_authors                                       |
| Female_authorship       | Float (0–1) | 0 if Female_authorship_ratio < .5; Female_authorship_ratio if >= 0.5 |
| Solo_authored_paper     | Binary      | 1 if total authors = 1                                               |
| over_half_female        | Binary      | 1 if Female_authorship_ratio > 0.5                                   |
| at_least_one_female     | Binary      | 1 if Female_authorship ≥ 1                                           |
| Single_gender_paper     | Binary      | 1 if all authors share same gender                                   |

---

# PART V — LLM Writing-Style Evaluation Variables

These variables are generated using a structured 16-dimension rubric.
Each dimension is scored on a continuous 1–10 scale.

Higher values reflect stronger presence of the defined stylistic attribute.

---

## Rubric Dimensions

### 1. Modal Verb Strength
Balance of weak ("may", "might") vs. strong ("will", "cannot") modals.  
1 = Only weak | 10 = Only strong

### 2. Hedging Frequency & Type
Frequency of stance phrases ("it seems that", "we believe").  
1 = Continuous hedging | 10 = No hedges

### 3. Qualifier Density
Use of softening modifiers ("relatively", "to some extent").  
1 = Extensive | 10 = None

### 4. Acknowledgement of Limitations
Explicit discussion of caveats or boundary conditions.  
1 = Numerous | 10 = None or implicit only

### 5. Caution-Signaling Connectors
Use of "however", "nevertheless", etc.  
1 = Frequent | 5 = Occasional | 10 = None

### 6. Assertiveness & Voice
Proportion of assertive vs. tentative verbs.  
1 = Almost all tentative | 10 = Almost all assertive

### 7. Active/Passive Voice Ratio
Active vs. passive construction balance.  
1 = ~90% passive | 5 = Balanced | 10 = ~90% active

### 8. Sentence Length & Directness
Degree of multi-clausal complexity.  
1 = Very long/convoluted | 10 = Very short/direct

### 9. Imperative-Form Occurrence
Presence of direct commands.  
1 = None | 10 = Dominant

### 10. Pronoun Commitment
First-person vs. impersonal construction.  
1 = Fully impersonal | 10 = Fully first-person

### 11. Novelty-Claim Strength
Boldness of originality claims.  
1 = None | 5 = Hedged | 10 = Grandiose

### 12. Jargon/Technicality Density
Density of undefined field-specific terminology.  
1 = Minimal | 10 = Dense

### 13. Emotional Valence
Presence of emotionally charged language.  
1 = None | 10 = Frequent

### 14. Evidence & Citation Usage
Degree to which claims are supported.  
1 = None | 10 = Every claim backed

### 15. Practical/Impact Orientation
Emphasis on real-world implications.  
1 = None | 5 = Informative | 10 = Transformative

### 16. Readability
Ease with which text can be understood.  
1 = Difficult | 10 = Extremely easy

---

# Measurement Notes

- Rubric scores are model-generated (GPT-5).
- All rubric variables are continuous on a 1–10 scale.
- Higher values reflect stylistic intensity, not normative quality.
- Gender variables are probabilistic and subject to classification uncertainty.
- Citation counts are time-dependent.
- Correspondence tables define many-to-many mappings.

---
