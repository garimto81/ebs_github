FROM python:3.12-slim

WORKDIR /app

COPY pyproject.toml .
RUN pip install --no-cache-dir .

COPY src/ src/
COPY tools/ tools/
COPY migrations/ migrations/
COPY alembic.ini alembic.ini
COPY entrypoint.sh entrypoint.sh
# V9.5 P17: CRLF → LF (Windows 작성 file 호환)
RUN sed -i 's/\r$//' entrypoint.sh && chmod +x entrypoint.sh

EXPOSE 8000

ENTRYPOINT ["./entrypoint.sh"]
CMD ["uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8000"]
