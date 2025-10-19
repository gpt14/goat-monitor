FROM python:3.11-slim

WORKDIR /app
COPY exporter.py .

RUN pip install prometheus_client requests

EXPOSE 8000

ENV GOAT_RPC_URL=

CMD ["python", "exporter.py"]
