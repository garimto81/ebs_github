from pydantic import BaseModel


class SeriesCreate(BaseModel):
    series_name: str
    competition_id: int
    year: int
    begin_at: str
    end_at: str
    time_zone: str = "UTC"
    currency: str = "USD"
    country_code: str | None = None


class SeriesUpdate(BaseModel):
    series_name: str | None = None
    year: int | None = None
    begin_at: str | None = None
    end_at: str | None = None
    time_zone: str | None = None
    currency: str | None = None
    country_code: str | None = None


class SeriesRead(BaseModel):
    series_id: int
    competition_id: int
    series_name: str
    year: int
    begin_at: str
    end_at: str
    time_zone: str
    currency: str
    country_code: str | None
    created_at: str
    updated_at: str
