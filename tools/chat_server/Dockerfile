FROM python:3.11-slim
WORKDIR /app

# 의존성 (Docker layer cache 효율 위해 먼저)
COPY tools/chat_server/requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# 앱 코드 (broker_client import 위해 message_bus 경로 포함)
COPY tools/orchestrator/message_bus/__init__.py /app/tools/orchestrator/message_bus/__init__.py
COPY tools/chat_server /app/tools/chat_server

# PYTHONPATH 로 절대 import 활성
ENV PYTHONPATH=/app
ENV BROKER_URL=http://host.docker.internal:7383/mcp
ENV LOG_LEVEL=INFO

EXPOSE 7390
HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:7390/health', timeout=2)" || exit 1

CMD ["uvicorn", "tools.chat_server.server:app", "--host", "0.0.0.0", "--port", "7390"]
