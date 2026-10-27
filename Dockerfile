# ---------- Build stage ----------
FROM python:3.13-slim AS build

WORKDIR /app

COPY requirements.txt .

# 1) Install app dependencies into /deps
# 2) THEN force the patched versions (order matters)
RUN python -m pip install --no-cache-dir --target=/deps -r requirements.txt && \
    python -m pip install --no-cache-dir --upgrade --target=/deps \
        "msgpack>=1.2.1" \
        "urllib3>=2.8.0" \
        "setuptools>=78.1.1"

COPY app.py .

# ---------- Runtime stage ----------
FROM gcr.io/distroless/python3-debian13:nonroot

WORKDIR /app

COPY --from=build /deps /deps
COPY --from=build /app/app.py .

ENV PYTHONPATH=/deps \
    PYTHONUNBUFFERED=1

CMD ["app.py"]
