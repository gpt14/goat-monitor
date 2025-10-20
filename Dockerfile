FROM python:3.11-slim

ENV GOAT_RPC_NODE=

WORKDIR /app

COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

COPY exporter.py .

EXPOSE 8000

USER nobody

CMD ["python", "exporter.py"]
