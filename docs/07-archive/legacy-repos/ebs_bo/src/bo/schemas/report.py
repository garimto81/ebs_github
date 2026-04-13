from pydantic import BaseModel


class ReportData(BaseModel):
    report_type: str
    generated_at: str
    data: list[dict]
