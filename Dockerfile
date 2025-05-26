# Use minimal Python image
FROM python:3.9-slim

# --- Build-time arguments for Seal ---
ARG SEAL_TOKEN
ARG SEAL_PROJECT

# --- Set working directory ---
WORKDIR /app

# --- Copy application and Seal config ---
COPY requirements.txt .
COPY app.py .
COPY .seal-actions.yml .

# --- Single RUN layer: install tools, install dependencies, run Seal fix, clean up ---
RUN apt-get update && apt-get install -y unzip curl && \
    pip install --upgrade pip && \
    pip install -r requirements.txt && \
    curl -fsSL https://github.com/seal-community/cli/releases/download/latest/seal-linux-amd64-latest.zip -o /tmp/seal.zip && \
    unzip /tmp/seal.zip -d /usr/local/bin && \
    chmod +x /usr/local/bin/seal && \
    SEAL_TOKEN=$SEAL_TOKEN SEAL_PROJECT=$SEAL_PROJECT seal fix --mode local --upload-scan-results && \
    rm -f /tmp/seal.zip /usr/local/bin/seal

# --- Run the app ---
CMD ["python", "app.py"]
