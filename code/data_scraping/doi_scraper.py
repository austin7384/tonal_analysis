"""
DOI Abstract & Acceptance Information Scraper

Scrapes:
- Abstract
- Acceptance / editorial information (if present)

Strategy:
- One fresh Selenium browser per DOI
- Minimal, reliable DOM parsing
- Publisher-agnostic with INFORMS support

Requirements:
    pip install pandas selenium beautifulsoup4 webdriver-manager
"""

import time
import random
from typing import Optional, Dict

import pandas as pd
from bs4 import BeautifulSoup

from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

from webdriver_manager.chrome import ChromeDriverManager

CHROMELABS_ERROR = "googlechromelabs.github.io"
MAX_RETRIES = 2
PAUSE_SECONDS = 60


def should_pause_and_retry(error: str) -> bool:
    return CHROMELABS_ERROR in error

def clean_doi_link(raw: str) -> str:
    """
    Normalize DOI links by removing trailing whitespace and
    accidental appended text (e.g., 'Abstract').
    """
    if not isinstance(raw, str):
        return raw

    # Keep only the first line, strip whitespace
    return raw.strip().splitlines()[0]

def create_driver() -> webdriver.Chrome:
    """
    Create a fresh, headless Chrome WebDriver instance.
    A new browser is required for each DOI to avoid session-based blocking.
    """

    options = Options()
    options.add_argument("--headless=new")
    options.add_argument("--disable-gpu")
    options.add_argument("--window-size=1920,1080")
    options.add_argument("--disable-blink-features=AutomationControlled")

    # Stable, realistic UA
    options.add_argument(
        "user-agent=Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
        "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    )

    service = Service(ChromeDriverManager().install())
    driver = webdriver.Chrome(service=service, options=options)

    # Remove webdriver fingerprint
    driver.execute_script(
        "Object.defineProperty(navigator, 'webdriver', {get: () => undefined})"
    )

    return driver

def scrape_doi_info(doi_url: str, verbose: bool = False) -> Dict[str, Optional[str]]:
    """
    Scrape abstract and acceptance information from a single DOI page.
    """

    result = {
        "abstract": None,
        "acceptance_info": None,
        "error": None,
    }

    driver = None

    try:
        driver = create_driver()

        if verbose:
            print(f"Loading {doi_url}")

        driver.get(doi_url)

        # Wait for DOM to exist
        WebDriverWait(driver, 15).until(
            EC.presence_of_element_located((By.TAG_NAME, "body"))
        )

        # Light scroll to trigger lazy content
        time.sleep(random.uniform(1.0, 2.0))
        driver.execute_script("window.scrollTo(0, document.body.scrollHeight / 2);")
        time.sleep(random.uniform(1.0, 2.0))

        soup = BeautifulSoup(driver.page_source, "html.parser")

        # -----------------------------
        # ABSTRACT EXTRACTION
        # -----------------------------
        abstract = None

        # INFORMS-specific (primary)
        abstract_div = soup.find("div", class_="abstractSection")
        if abstract_div:
            paragraphs = abstract_div.find_all("p", recursive=False)
            if paragraphs:
                abstract = " ".join(p.get_text(strip=True) for p in paragraphs)

        # Generic fallback
        if not abstract:
            meta = soup.find("meta", attrs={"name": "dc.description"})
            if meta and meta.get("content"):
                abstract = meta["content"].strip()

        if abstract:
            abstract = " ".join(abstract.split())
            if len(abstract) > 3000:
                abstract = abstract[:3000] + "..."

        result["abstract"] = abstract

        # -----------------------------
        # ACCEPTANCE INFORMATION
        # -----------------------------
        acceptance_keywords = [
            "accepted by",
        ]

        acceptance_info = None

        # INFORMS places acceptance text near abstract
        if abstract_div:
            for sibling in abstract_div.find_next_siblings(limit=6):
                text = sibling.get_text(strip=True)
                if (
                    30 < len(text) < 500
                    and any(k in text.lower() for k in acceptance_keywords)
                ):
                    acceptance_info = text
                    break

        # Global fallback
        if not acceptance_info:
            for p in soup.find_all("p"):
                text = p.get_text(strip=True)
                if (
                    30 < len(text) < 500
                    and any(k in text.lower() for k in acceptance_keywords)
                ):
                    acceptance_info = text
                    break

        if acceptance_info:
            acceptance_info = " ".join(acceptance_info.split())

        result["acceptance_info"] = acceptance_info

        if verbose:
            print(
                f"✓ Abstract: {len(abstract) if abstract else 0} chars | "
                f"Acceptance: {'Yes' if acceptance_info else 'No'}"
            )

    except Exception as e:
        result["error"] = str(e)
        if verbose:
            print(f"✗ Error: {e}")

    finally:
        if driver:
            driver.quit()

    return result

def scrape_multiple_dois(
    df: pd.DataFrame,
    link_column: str = "link",
    delay: float = 3.0,
    verbose: bool = True,
) -> pd.DataFrame:
    """
    Scrape abstracts and acceptance info for all DOIs in a DataFrame.
    Uses a fresh browser session per DOI.
    Retries DOI after pause if Chromedriver resolution fails.
    """

    df_out = df.copy()
    df_out["abstract"] = None
    df_out["acceptance_info"] = None
    df_out["scrape_error"] = None

    for i, row in df_out.iterrows():
        doi = clean_doi_link(row[link_column])
        print(f"\n[{i + 1}/{len(df_out)}] {doi}")

        attempt = 0

        while attempt <= MAX_RETRIES:
            info = scrape_doi_info(doi, verbose=verbose)

            # Successful Run
            if info["error"] is None:
                df_out.at[i, "abstract"] = info["abstract"]
                df_out.at[i, "acceptance_info"] = info["acceptance_info"]
                df_out.at[i, "scrape_error"] = None
                break

            # Unsuccessful Run
            attempt += 1

            if should_pause_and_retry(info["error"]) and attempt <= MAX_RETRIES:
                print(
                    f"⚠ Chromedriver resolution error detected. "
                    f"Pausing {PAUSE_SECONDS}s before retry "
                    f"({attempt}/{MAX_RETRIES})..."
                )
                time.sleep(PAUSE_SECONDS)
                continue

            # Non-retryable or final failure
            print(f"✗ Error: {info['error']}")
            df_out.at[i, "scrape_error"] = info["error"]
            break

        if i < len(df_out) - 1:
            time.sleep(delay * random.uniform(0.8, 1.4))

    return df_out