# Base image
FROM python:3.10-slim

# Metadata GHCR
LABEL org.opencontainers.image.source="https://github.com/linea-enfasis/project-api-python"

# Environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    POETRY_VERSION=1.4.2 \
    POETRY_NO_INTERACTION=1 \
    POETRY_VIRTUALENVS_CREATE=false \
    POETRY_CACHE_DIR='/var/cache/pypoetry' \
    POETRY_HOME='/usr/local' \
    PATH="/root/.local/bin:$PATH"

# System dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    libpq-dev \
    curl \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Poetry
RUN curl -sSL https://install.python-poetry.org | python3 -

# Workdir
WORKDIR /app

# Dependencies first (Docker cache)
COPY pyproject.toml poetry.lock* ./

RUN poetry install --no-dev --no-root

# Copy app
COPY . .

# Security - non root user
RUN useradd -m appuser
USER appuser

# Expose port
EXPOSE 8000

# Healthcheck
HEALTHCHECK CMD curl --fail http://localhost:${PORT:-8000}/health || exit 1

# Start app
CMD ["sh", "-c", "uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000}"]