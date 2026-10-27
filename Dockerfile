
FROM python:3.13-slim

WORKDIR /app

# Update Debian packages available in the base image repositories
RUN apt-get update && \
    apt-get upgrade -y && \
    rm -rf /var/lib/apt/lists/*

COPY requirements.txt .

# Upgrade the reported Python packages
RUN python -m pip install --no-cache-dir --upgrade \
    "msgpack>=1.2.1" \
    "setuptools>=78.1.1" \
    "urllib3>=2.8.0" && \
    python -m pip install --no-cache-dir -r requirements.txt

COPY app.py .
COPY test_app.py .

CMD ["python", "app.py"]
