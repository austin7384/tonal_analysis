import pandas as pd
from doi_scraper import scrape_multiple_dois
from parse_acceptance import parse_acceptance_info
from parse_abstract import strip_non_abstract_tail

# Load your data
df = pd.read_csv('/Users/austincoffelt/Documents/Who_Writes_What/data/raw/links_to_scrape.csv')
df.drop('Unnamed: 0', axis=1, inplace=True)

# Scrape all DOIs
df_results = scrape_multiple_dois(df)

# parse acceptance info for person and department
parsed = df_results["acceptance_info"].apply(parse_acceptance_info)
df_results["accepted_by"] = parsed.apply(lambda x: x["editor"])
df_results["department"] = parsed.apply(lambda x: x["department"])

# get only abstract from abstract
df_results['cleaned_abstracts'] = df_results['abstract'].apply(strip_non_abstract_tail)

# Save results
df_results.to_csv('/Users/austincoffelt/Documents/Who_Writes_What/data/processed/scraped_results1.csv', index=False)