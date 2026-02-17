import pandas as pd
import requests
import uuid

API_KEY = ''

URL = "https://v2.namsor.com/NamSorAPIv2/api2/json/genderFullBatch"

HEADERS = {
    "X-API-KEY": API_KEY,
    "Accept": "application/json",
    "Content-Type": "application/json"
}

def namsor_gender_full_batch(names):

    payload = {
        "personalNames": [
            {
                "id": str(uuid.uuid4()),
                "name": name
            }
            for name in names
            if pd.notna(name) and str(name).strip() != ""
        ]
    }

    response = requests.post(URL, json=payload, headers=HEADERS, timeout=30)
    response.raise_for_status()

    results = {}
    for entry in response.json()["personalNames"]:
        results[entry["id"]] = (
            entry.get("likelyGender"),
            entry.get("probabilityCalibrated")
        )

    return payload["personalNames"], results