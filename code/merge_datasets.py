import pandas as pd

hengel = pd.read_csv('/data/processed/llm_evaluated/clean_evaluations/Hengel_evaluations.csv')
scraped = pd.read_csv('/data/processed/llm_evaluated/clean_evaluations/ready_results.csv')

print(list(hengel.columns))
print('-----------------------------')
print(list(scraped.columns))

hengel.rename(columns={'PubDate':'Publsh_date', 'Title_PBLSH':'Title', 'Abstract_PBLSH':'Abstract', 'evaluation_pblsh_parsed':'Evaluation', 'AuthorName':'Author_name', 'NativeLanguage':'Native_language'}, inplace=True)
hengel.drop(columns=['Unnamed: 0', 'NberID', 'ArticleID', 'WPDate', 'Title_NBER', 'Abstract_NBER', 'Note_NBER', 'Volume', 'Issue', 'Part', 'FirstPage', 'LastPage', 'evaluation_nber_parsed', 'AuthorID'], inplace=True)

print('-----------------------------')
print(list(hengel.columns))

scraped.rename(columns={'title':'Title', 'metrics':'Metrics', 'received':'Received', 'accepted':'Accepted', 'published_online':'Publsh_date', 'accepted_by':'Accepted_by', 'department':'Department', 'evaluations':'Evaluation', 'author_name':'Author_name', 'gender_namsor':'Sex', 'gender_prob_namsor':'Sex_probability'}, inplace=True)
scraped.drop(columns=['Unnamed: 0', 'ArticleID', 'link', 'authors', 'under_review', 'pub_year', 'pub_month', 'paper_author_id', 'total_authors'], inplace=True)
scraped['Journal'] = 'MgSc'

print('-----------------------------')
print(list(scraped.columns))