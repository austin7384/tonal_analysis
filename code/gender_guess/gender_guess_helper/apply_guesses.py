import pandas as pd
from gender_guesser import namsor_gender_full_batch

def add_gender_namsor_fullname(df, name_col):
    df = df.copy()

    df["gender_namsor"] = None
    df["gender_prob_namsor"] = None

    # deduplicate full names
    unique_names = (
        df[name_col]
        .dropna()
        .astype(str)
        .str.strip()
        .loc[lambda x: x != ""]
        .unique()
        .tolist()
    )

    gender_map = {}

    for i in range(0, len(unique_names), 100):
        batch_names = unique_names[i:i + 100]
        payload_names, results = namsor_gender_full_batch(batch_names)

        for entry in payload_names:
            gender, prob = results.get(entry["id"], (None, None))
            gender_map[entry["name"]] = (gender, prob)

    # map back to full dataframe
    df["gender_namsor"] = df[name_col].map(
        lambda x: gender_map.get(x, (None, None))[0]
        if pd.notna(x) else None
    )

    df["gender_prob_namsor"] = df[name_col].map(
        lambda x: gender_map.get(x, (None, None))[1]
        if pd.notna(x) else None
    )

    return df