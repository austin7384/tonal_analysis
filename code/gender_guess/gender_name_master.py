import pandas as pd
from gender_guess_helper.apply_guesses import add_gender_namsor_fullname

# read in data
authors = pd.read_csv('~/Documents/Who_Writes_What/data/processed/author_level.csv')

df = add_gender_namsor_fullname(authors, "author_name")

df.to_csv('~/Documents/Who_Writes_What/data/processed/llm_evaluated/clean_evaluations/full_results_clean_gender_guess.csv', index=False)