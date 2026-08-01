from typing import Optional
from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    PROJECT_NAME: str = "EduVerse API"
    VERSION: str = "0.1.0"
    API_V1_STR: str = "/api/v1"
    ENVIRONMENT: str = "development"
    SECRET_KEY: str = "eduverse-secret-key-phase0-local-dev"

    # Supabase Configuration
    SUPABASE_URL: Optional[str] = "https://mock-supabase-id.supabase.co"
    SUPABASE_KEY: Optional[str] = "mock-supabase-key"

    # Gemini API Key
    GEMINI_API_KEY: Optional[str] = ""

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore"
    )

settings = Settings()
