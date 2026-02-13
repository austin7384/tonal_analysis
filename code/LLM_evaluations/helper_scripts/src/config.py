from openai import OpenAI
import logging

MODEL = 'gpt-5'
API_KEY = 'REMOVED'
TIMEOUT = 300

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