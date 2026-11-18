"""
config.py — Application configuration loaded from .env file.
"""

import os
from pathlib import Path
from dotenv import load_dotenv

# Load environment variables from backend/.env or root .env file
env_path = Path(__file__).resolve().parent / ".env"
load_dotenv(dotenv_path=env_path)
load_dotenv()


class Settings:
    # Database settings
    DB_HOST: str = os.getenv("DB_HOST", "localhost")
    DB_PORT: int = int(os.getenv("DB_PORT", "3306"))
    DB_NAME: str = os.getenv("DB_NAME", "tracer_db")
    DB_USER: str = os.getenv("DB_USER", "root")
    DB_PASSWORD: str = os.getenv("DB_PASSWORD", "")

    # Server settings
    SERVER_HOST: str = os.getenv("SERVER_HOST", "http://localhost:8000")

    # Build the SQLAlchemy database URL
    @property
    def DATABASE_URL(self) -> str:
        return (
            f"mysql+pymysql://{self.DB_USER}:{self.DB_PASSWORD}"
            f"@{self.DB_HOST}:{self.DB_PORT}/{self.DB_NAME}"
        )

    # IP geolocation API (ip-api.com — free, no key required)
    IP_API_URL: str = "http://ip-api.com/json/{ip}"

    # Mock location used when IP is localhost/127.0.0.1 (for local dev/testing)
    MOCK_LOCATION: dict = {
        "country": "India",
        "regionName": "Maharashtra",
        "city": "Mumbai",
        "lat": 19.0760,
        "lon": 72.8777,
        "isp": "Local Network",
        "status": "success",
    }


settings = Settings()
