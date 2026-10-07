"""Payment provider settings - credentials come from the environment, never from source."""
import os

PAYMENT_API_KEY = os.environ.get("PAYMENT_API_KEY", "")
PAYMENT_TIMEOUT_SECONDS = int(os.environ.get("PAYMENT_TIMEOUT_SECONDS", "5"))
