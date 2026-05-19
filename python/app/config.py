from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    database_url: str = "postgresql://kickai:password@db/kickai_production"
    redis_url: str = "redis://redis:6379/0"
    api_secret_key: str = ""
    football_data_api_key: str = ""
    environment: str = "production"

    model_config = {"env_file": ".env", "extra": "ignore"}


settings = Settings()
