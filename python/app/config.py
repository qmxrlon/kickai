from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    # No default with credentials: DATABASE_URL must come from the environment
    database_url: str = ""
    redis_url: str = "redis://redis:6379/0"
    api_secret_key: str = ""
    football_data_api_key: str = ""
    environment: str = "production"

    model_config = {"env_file": ".env", "extra": "ignore"}


settings = Settings()
