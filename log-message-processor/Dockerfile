# Use Python 3.9 slim image (compatible with 3.6+ requirements)
FROM python:3.9-slim

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first for better caching
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Create non-root user for security
RUN adduser --disabled-password --gecos '' appuser && \
    chown -R appuser:appuser /app
USER appuser

# Set environment variables with defaults
ENV REDIS_HOST=localhost
ENV REDIS_PORT=6379
ENV REDIS_CHANNEL=log_channel

# Run the application
CMD ["python3", "main.py"]