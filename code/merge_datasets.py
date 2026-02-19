import pandas as pd

# read in data
hengel = pd.read_csv('~/tonal_analysis/data/processed/llm_evaluated/clean_evaluations/Hengel_evaluations.csv')
scraped = pd.read_csv('~/tonal_analysis/data/processed/llm_evaluated/clean_evaluations/ready_results.csv')

# preparing hengel data for merging
hengel.rename(columns={'PubDate':'Publsh_date', 'Title_PBLSH':'Title', 'Abstract_PBLSH':'Abstract', 'evaluation_pblsh_parsed':'Evaluation', 'AuthorName':'Author_name', 'NativeLanguage':'Native_language'}, inplace=True)
hengel.drop(columns=['Unnamed: 0', 'NberID', 'WPDate', 'Title_NBER', 'Abstract_NBER', 'Note_NBER', 'Note_PBLSH', 'Volume', 'Issue', 'Part', 'FirstPage', 'LastPage', 'evaluation_nber_parsed', 'AuthorID'], inplace=True)

# preparing scraped data for merging
scraped.rename(columns={'title':'Title', 'metrics':'Metrics', 'received':'Received', 'accepted':'Accepted', 'published_online':'Publsh_date', 'accepted_by':'Accepted_by', 'department':'Department', 'evaluations':'Evaluation', 'author_name':'Author_name', 'gender_namsor':'Sex', 'gender_prob_namsor':'Sex_probability'}, inplace=True)
scraped.drop(columns=['Unnamed: 0', 'link', 'authors', 'under_review', 'pub_year', 'pub_month', 'paper_author_id', 'total_authors'], inplace=True)
scraped['Journal'] = 'MgSc'
scraped['ArticleID'] += 15000

# merging dataframe
merged_df = pd.concat([hengel, scraped])
merged_df.drop_duplicates(subset=['ArticleID', 'Author_name', 'Abstract'], keep='last', inplace=True)
merged_df.to_csv('~/tonal_analysis/data/processed/llm_evaluated/clean_evaluations/merged_evaluations.csv')