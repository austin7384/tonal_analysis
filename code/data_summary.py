import pandas as pd

df = pd.read_csv('~/Documents/Who_Writes_What/data/processed/llm_evaluated/clean_evaluations/ready_results.csv')
df.drop(columns=["Unnamed: 0"], inplace=True)

# --- 1. Gender counts at the author level ---
gender_counts = (
    df.groupby('gender_namsor')
      .size()
      .reset_index(name='author_count')
)

print("\nAuthor-Level Gender Counts:")
print(gender_counts)


# --- 2. Construct paper-level dataframe ---
paper_df = (
    df.groupby('ArticleID')
      .agg(
          total_authors=('paper_author_id', 'count'),
          female_authors=('Female_authorship', 'sum'),
          female_ratio=('Female_authorship_ratio', 'max'),
          over_half_female=('over_half_female', 'max'),
          at_least_one_female=('at_least_one_female', 'max'),
          single_gender=('Single_gender_paper', 'max')
      )
      .reset_index()
)

# Identify single-gender female papers
paper_df['single_gender_female'] = (
    (paper_df['single_gender'] == 1) &
    (paper_df['female_ratio'] == 1)
).astype(int)

total_papers = len(paper_df)

summary_stats = pd.DataFrame({
    'Metric': [
        'Total Papers',
        'Percent Over Half Female',
        'Percent At Least One Female',
        'Percent Single-Gender Papers (Female Only)'
    ],
    'Value': [
        total_papers,
        100 * paper_df['over_half_female'].mean(),
        100 * paper_df['at_least_one_female'].mean(),
        100 * paper_df['single_gender_female'].sum() / total_papers
    ]
})

print("\nPaper-Level Summary Statistics:")
print(summary_stats)


# Get one row per paper with its accepting department
paper_departments = (
    df[['ArticleID', 'department']]
        .drop_duplicates()
)

department_counts = (
    paper_departments['department']
        .value_counts()
        .reset_index()
        .rename(columns={
            'index': 'Department',
            'department': 'Paper_Count'
        })
)

print("\nPapers Accepted by Department:")
print(department_counts.head(10))
