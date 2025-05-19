# Use minimal Python image
FROM python:3.9-slim

# --- Build-time arguments for Seal ---
ARG SEAL_TOKEN
ARG SEAL_PROJECT
ARG SEAL_CLI_VERSION=latest

# --- Make them available to the CLI inside the container ---
ENV SEAL_TOKEN=$SEAL_TOKEN
ENV SEAL_PROJECT=$SEAL_PROJECT

# --- Set working directory ---
WORKDIR /app

# --- Copy application and Seal config ---
COPY requirements.txt .
COPY app.py .
COPY .seal-actions.yml .

# --- Add debug steps with detailed output ---
RUN echo "=============== INITIAL STATE ===============" && \
    echo "Python version:" && python --version && \
    echo "Pip version:" && pip --version && \
    echo "Initial site-packages:" && ls -la /usr/local/lib/python3.9/site-packages/ | grep -i yaml

# --- Install tools and Python deps with verbose output ---
RUN apt-get update && \
    apt-get install -y --no-install-recommends unzip curl && \
    pip install --no-cache-dir --upgrade pip && \
    echo "=============== INSTALLING REQUIREMENTS ===============" && \
    pip install -v --no-cache-dir -r requirements.txt && \
    echo "=============== PIP LIST AFTER REQUIREMENTS ===============" && \
    pip list && \
    echo "=============== DETAILED PYYAML INFO BEFORE PATCHING ===============" && \
    pip show pyyaml && \
    echo "=============== SITE-PACKAGES AFTER REQUIREMENTS ===============" && \
    ls -la /usr/local/lib/python3.9/site-packages/ | grep -i yaml && \
    echo "=============== INSTALLED FILES FOR PYYAML ===============" && \
    pip show -f pyyaml | grep -i "\.py" | sort

# --- Install and run Seal CLI with verbose output ---
RUN echo "=============== INSTALLING SEAL CLI ===============" && \
    curl -fsSL "https://github.com/seal-community/cli/releases/download/v${SEAL_CLI_VERSION}/seal-linux-amd64-${SEAL_CLI_VERSION}.zip" -o /tmp/seal.zip && \
    unzip /tmp/seal.zip -d /usr/local/bin && \
    chmod +x /usr/local/bin/seal && \
    echo "=============== SEAL CLI VERSION ===============" && \
    seal --version && \
    echo "=============== SEAL CONFIG ===============" && \
    cat .seal-actions.yml && \
    echo "=============== RUNNING SEAL FIX ===============" && \
    seal fix --mode local -v && \
    echo "=============== PIP LIST AFTER PATCHING ===============" && \
    pip list && \
    echo "=============== DETAILED PYYAML INFO AFTER PATCHING ===============" && \
    pip show pyyaml || echo "PyYAML not found with pip show" && \
    echo "=============== SITE-PACKAGES AFTER PATCHING ===============" && \
    ls -la /usr/local/lib/python3.9/site-packages/ | grep -i yaml && \
    echo "=============== PIP LIST ALL YAML PACKAGES ===============" && \
    pip list | grep -i yaml && \
    echo "=============== PYTHON IMPORT TEST ===============" && \
    python -c "import yaml; print(f'PyYAML version: {yaml.__version__}'); print(f'PyYAML file location: {yaml.__file__}')"

# --- Check dist-packages location as well ---
RUN echo "=============== CHECK DIST-PACKAGES ===============" && \
    ls -la /usr/lib/python3/dist-packages/ | grep -i yaml || echo "No YAML files in dist-packages"

# --- Create a simple diagnostic script ---
RUN echo 'import sys, os, pkg_resources\n\
print("Python paths:")\n\
for path in sys.path: print(f"  {path}")\n\
print("\\nPyYAML locations search:")\n\
for path in sys.path:\n\
    yaml_path = os.path.join(path, "yaml")\n\
    if os.path.exists(yaml_path):\n\
        print(f"  Found yaml at: {yaml_path}")\n\
print("\\nPyYAML via pkg_resources:")\n\
try:\n\
    dist = pkg_resources.get_distribution("PyYAML")\n\
    print(f"  Version: {dist.version}")\n\
    print(f"  Location: {dist.location}")\n\
except pkg_resources.DistributionNotFound:\n\
    print("  No PyYAML distribution found")\n\
' > /app/diagnose_yaml.py && \
    echo "=============== RUNNING DIAGNOSTIC SCRIPT ===============" && \
    python /app/diagnose_yaml.py

# --- Cleanup for final image ---
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/seal.zip

# --- Run the app ---
CMD ["python", "app.py"]
