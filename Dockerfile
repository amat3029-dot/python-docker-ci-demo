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

# Trim what the runtime doesn't need (pip, test suite)
RUN rm -rf /usr/local/lib/python3.13/site-packages/pip* \
           /usr/local/lib/python3.13/test \
           /usr/local/bin/pip*

# Collect the shared libraries Python needs (zlib, ssl, ffi, expat, sqlite...),
# skipping libc/gcc (already in the base) and the vulnerable
# ncurses / util-linux / readline libs.
RUN set -eux; \
    mkdir -p /rootfs; \
    { echo /usr/local/bin/python3.13; find /usr/local/lib -name '*.so*' -type f; } \
      | xargs ldd 2>/dev/null \
      | awk '/=> \//{print $3}' | sort -u \
      | grep -Ev '/(libc|libm|libdl|libpthread|librt|libutil|libresolv|libgcc_s|libstdc\+\+|ld-linux[^/]*|libtinfo|libncursesw?|libpanelw?|libformw?|libmenuw?|libuuid|libreadline|libedit)\.so' \
      | xargs -I{} cp --parents -L {} /rootfs/

# ---------- Runtime stage ----------
FROM gcr.io/distroless/cc-debian13:nonroot

WORKDIR /app

COPY --from=build /rootfs/ /
COPY --from=build /usr/local /usr/local
COPY --from=build /deps /deps
COPY --from=build /app/app.py .

ENV PYTHONPATH=/deps \
    LD_LIBRARY_PATH=/usr/local/lib \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

ENTRYPOINT ["/usr/local/bin/python3.13"]
CMD ["app.py"]
