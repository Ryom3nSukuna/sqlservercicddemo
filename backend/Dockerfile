# Base image
FROM python:3.9-slim

# Install required dependencies
RUN apt-get update && apt-get install -y \
    gnupg \
    gnupg2 \
    unixodbc \
    unixodbc-dev \
    libodbc1 \
    g++ \
    curl \
    && curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - \
    && curl https://packages.microsoft.com/config/debian/10/prod.list > /etc/apt/sources.list.d/mssql-release.list \
    && apt-get update \
    && ACCEPT_EULA=Y apt-get install -y msodbcsql17

# Set working directory
WORKDIR /app

# Copy requirements and install Python packages
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the application code
COPY . .

# Expose the Flask app port
EXPOSE 5000

# Start the Flask app
CMD ["bash", "-c", "python wait_for_sqlserver.py && exec gunicorn -w 4 -b 0.0.0.0:5000 app.routes:app"]
