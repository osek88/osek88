# Use minimal Python image
FROM python:3.9-slim

# --- Build-time arguments for Seal ---
ARG SEAL_TOKEN
ARG SEAL_PROJECT

# --- Make them available as environment variables ---
ENV SEAL_TOKEN=$SEAL_TOKEN
ENV SEAL_PROJECT=$SEAL_PROJECT
ENV SEAL_CLI_VERSION=latest

# --- Set working directory ---
WORKDIR /app

# --- Copy application and Seal config ---
COPY requirements.txt .
COPY app.py .
COPY .seal-actions.yml .

# --- Install tools and Python dependencies ---
RUN apt-get update && apt-get install -y unzip curl && \
    pip install --upgrade pip && \
    pip install -r requirements.txt

# --- Install and run Seal CLI in local mode and upload scan results ---
RUN curl -fsSL https://github.com/seal-community/cli/releases/download/${SEAL_CLI_VERSION}/seal-linux-amd64-${SEAL_CLI_VERSION}.zip -o /tmp/seal.zip && \
    unzip /tmp/seal.zip -d /usr/local/bin && \
    chmod +x /usr/local/bin/seal && \
    SEAL_TOKEN=$SEAL_TOKEN SEAL_PROJECT=$SEAL_PROJECT seal fix --mode local --upload-scan-results && \
    rm -f /tmp/seal.zip /usr/local/bin/seal

# --- Run the app ---
CMD ["python", "app.py"]
