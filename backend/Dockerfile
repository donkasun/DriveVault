# Production image for Render (see docs/01-tech-spec.md §6).
FROM python:3.12-slim

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

WORKDIR /app

COPY pyproject.toml ./
RUN pip install --no-cache-dir --upgrade pip && pip install --no-cache-dir .

COPY app ./app

EXPOSE 8000

# Render provides $PORT; default to 8000 locally.
CMD ["sh", "-c", "gunicorn app.main:app -k uvicorn.workers.UvicornWorker -b 0.0.0.0:${PORT:-8000}"]
