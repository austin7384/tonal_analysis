import pandas as pd

IMPORT_CSV = '~/Documents/Who_Writes_What/data/processed/llm_evaluated/clean_evaluations/full_results_clean.csv'
EXPORT_AUTHORS = '~/Documents/Who_Writes_What/data/processed/author_level.csv'

df = pd.read_csv(IMPORT_CSV)
df.drop('Unnamed: 0', axis=1, inplace=True)

# split authors
df["author_list"] = (
    df["authors"]
      .str.split(",")
      .apply(lambda xs: [x.strip() for x in xs if x.strip()])
)

# explode to author-level
df_authors = df.explode("author_list").reset_index(drop=True)
df_authors.rename(columns={"author_list": "author_name"}, inplace=True)

# stable identifier (paper × author)
df_authors["paper_author_id"] = (
    df_authors["ArticleID"].astype(str) + "_" +
    df_authors.groupby("ArticleID").cumcount().astype(str)
)

# get author counts
paper_author_counts = df.groupby("ArticleID").size()
df['total_authors'] = df['ArticleID'].map(paper_author_counts)

# no articles with >10 authors
df = df[df['total_authors'] < 10]

df_authors.to_csv(EXPORT_AUTHORS, index=False)