from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Runtime configuration. In Kubernetes these come from a ConfigMap (non-secret)
    and a Secret (DATABASE_URL), never from values baked into the image."""

    app_name: str = "SpendBoard API"
    app_version: str = "1.0.0"
    environment: str = "local"
    database_url: str = "sqlite:///./spendboard.db"
    currency: str = "INR"
    monthly_budget: float = 25000.0

    model_config = SettingsConfigDict(env_file=".env", extra="ignore")


settings = Settings()
