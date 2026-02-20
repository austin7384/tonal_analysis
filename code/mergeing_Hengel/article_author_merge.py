import pandas as pd

articles = pd.read_csv('~/tonal_analysis/data/processed/llm_evaluated/clean_evaluations/hengel_QJE.csv')
authors = pd.read_csv('~/tonal_analysis/data/raw/hengel_replication_data/Author.csv')
author_corr = pd.read_csv('~/tonal_analysis/data/raw/hengel_replication_data/AuthorCorr.csv')

authors = pd.merge(authors, author_corr, on='AuthorID')
articles = pd.merge(articles, authors, on='ArticleID')

articles.to_csv('~/tonal_analysis/data/processed/llm_evaluated/clean_evaluations/hengel_QJE_gender.csv')