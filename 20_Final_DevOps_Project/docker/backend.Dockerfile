# Build context: application/backend
# Stage 1 - install dependencies into a venv (needs pip, caches, build tooling)
FROM python:3.12-slim AS deps
ENV PIP_NO_CACHE_DIR=1 PIP_DISABLE_PIP_VERSION_CHECK=1
RUN python -m venv /venv
COPY requirements.txt .
RUN /venv/bin/pip install -r requirements.txt

# Stage 2 - runtime: just the venv + source, running as a fixed non-root UID
FROM python:3.12-slim
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1 PATH="/venv/bin:$PATH"
# libpq comes from Debian (patched by `apt-get upgrade`) instead of the psycopg[binary] wheel, whose
# vendored C libraries (an old libpcre2 among them) are invisible to the OS package manager.
RUN apt-get update \
 && apt-get upgrade -y \
 && apt-get install -y --no-install-recommends libpq5 \
 && rm -rf /var/lib/apt/lists/* \
 && useradd --uid 10001 --no-create-home --shell /usr/sbin/nologin app
WORKDIR /app
COPY --from=deps /venv /venv
COPY alembic.ini ./
COPY alembic ./alembic
COPY app ./app
USER 10001:10001
EXPOSE 8000
HEALTHCHECK --interval=30s --timeout=3s CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/health')"
# Migrations are a separate step (compose `migrate` service / k8s initContainer), not part of start-up.
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--proxy-headers"]
