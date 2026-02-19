import pandas as pd

from helper_scripts.batch_runner import batch_call_and_validate
from helper_scripts.rubric import CHECKLIST_RUBRIC


BATCH_SIZE = 1000
INPUT_CSV = "/Users/austincoffelt/Documents/Who_Writes_What/data/processed/scraped_results.csv"
OUTPUT_CSV = "/Users/austincoffelt/Documents/Who_Writes_What/data/processed/llm_evaluated/raw_evaluations/full_results.csv"


def main():
    # ------------------------------------------------------------
    # Load and filter dataset
    # ------------------------------------------------------------
    df = pd.read_csv(INPUT_CSV)
    df.drop(['abstract', 'acceptance_info', 'scrape_error'], axis=1, inplace=True)
    df.rename(columns={"Unnamed: 0": "ArticleID", 'cleaned_abstracts':'Abstract'}, inplace=True)
    df = df[~df['Abstract'].isna()]

    # Ensure IDs are strings (batch API expects string custom_ids)
    df["ArticleID"] = df["ArticleID"].astype(str)

    # ------------------------------------------------------------
    # Run batch evaluations in chunks
    # ------------------------------------------------------------
    all_results = []

    for start in range(0, len(df), BATCH_SIZE):
        end = start + BATCH_SIZE

        chunk = df.iloc[start:end]

        passages = chunk["Abstract"].tolist()
        custom_ids = chunk["ArticleID"].tolist()

        chunk_results = batch_call_and_validate(
            passages=passages,
            custom_ids=custom_ids,
            rubric_checklist=CHECKLIST_RUBRIC
        )

        all_results.extend(chunk_results)

    # ------------------------------------------------------------
    # Attach structured results and persist
    # ------------------------------------------------------------
    df['evaluations'] = None

    for result in all_results:
        row_index = df.index[df['ArticleID'] == result['id']]
        if not row_index.empty:  # just in case there’s no match
            df.at[row_index[0], 'evaluations'] = str(result['output'])

    df.to_csv(OUTPUT_CSV, index=False)

if __name__ == "__main__":
    main()
