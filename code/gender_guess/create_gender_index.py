import pandas as pd
import numpy as np

df = pd.read_csv('~/Documents/Who_Writes_What/data/processed/llm_evaluated/clean_evaluations/full_results_clean_gender_guess.csv')
# ------------------------------------------------------------------
# PAPER-LEVEL COUNTS
# ------------------------------------------------------------------

# total authors per paper
paper_author_counts = df.groupby("ArticleID").size()

# female authors per paper
female_author_counts = (
    df["gender_namsor"]
    .eq("female")
    .groupby(df["ArticleID"])
    .sum()
)

# ------------------------------------------------------------------
# FEMALE AUTHORSHIP RATIO
# ------------------------------------------------------------------

df["Female_authorship_ratio"] = (
    df["ArticleID"].map(female_author_counts)
    / df["ArticleID"].map(paper_author_counts)
)

# ------------------------------------------------------------------
# SOLO-AUTHORED PAPERS
# ------------------------------------------------------------------

df["Solo_authored_paper"] = (
    df["ArticleID"].map(paper_author_counts) == 1
).astype(int)

# ------------------------------------------------------------------
# FEMALE AUTHORSHIP (CONTINUOUS, ≥ 50% ONLY)
# ------------------------------------------------------------------

df["Female_authorship"] = np.where(
    df["Female_authorship_ratio"] >= 0.5,
    df["Female_authorship_ratio"],
    0.0
)

# ------------------------------------------------------------------
# BINARY INDICATORS
# ------------------------------------------------------------------

df["over_half_female"] = (
    df["Female_authorship_ratio"] >= 0.5
).astype(int)

df["at_least_one_female"] = (
    df["Female_authorship_ratio"] > 0
).astype(int)

df["Single_gender_paper"] = (
    (df["Female_authorship_ratio"] == 0) |
    (df["Female_authorship_ratio"] == 1)
).astype(int)

df.to_csv("~/Documents/Who_Writes_What/data/processed/llm_evaluated/clean_evaluations/ready_results.csv")