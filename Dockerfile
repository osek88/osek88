# Use minimal Python image
FROM python:3.9-slim

# --- Build-time arguments for Seal ---
ARG SEAL_TOKEN
ARG SEAL_PROJECT

# --- Make them available to the CLI inside the container ---
ENV SEAL_TOKEN=$SEAL_TOKEN
ENV SEAL_PROJECT=$SEAL_PROJECT
ENV SEAL_CLI_VERSION=latest

# --- Set working directory ---
WORKDIR /app

# --- Copy application and Seal config ---
COPY requirements.txt .
COPY app.py .
COPY .seal-actions.yml .

# --- Install tools and Python deps ---
RUN apt-get update && apt-get install -y unzip curl && \
    pip install --upgrade pip && \
    pip install -r requirements.txt

# --- Install and run Seal CLI in local mode to apply sealed patches ---
RUN curl -fsSL https://github.com/seal-community/cli/releases/download/${SEAL_CLI_VERSION}/seal-linux-amd64-${SEAL_CLI_VERSION}.zip -o /tmp/seal.zip && \
    unzip /tmp/seal.zip -d /usr/local/bin && \
    seal fix --mode local && \
    rm -f /tmp/seal.zip /usr/local/bin/seal

# --- Run the app ---
CMD ["python", "app.py"]
