from openai import OpenAI
import logging
import os
from dotenv import load_dotenv

load_dotenv()

MODEL = 'gpt-5'
API_KEY = os.getenv("OPENAI_API_KEY")
TIMEOUT = 300

if API_KEY is None:
    raise ValueError("OPENAI_API_KEY environment variable not set.")

client = OpenAI(
    api_key=API_KEY,
    timeout=TIMEOUT
)

logging.basicConfig(
    filename="/Users/austincoffelt/Documents/Who_Writes_What/data/raw/gpt_processing.log",
    level=logging.INFO,
    format="%(asctime)s - %(message)s"
)
logger = logging.getLogger(__name__)