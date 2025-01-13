# Use official Python image as the base
FROM python:3.9-slim

# Set working directory
WORKDIR /app

# Copy requirements.txt and install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the app's code
COPY . .

# Expose the port Flask will run on
EXPOSE 5001

# Run the Flask app
CMD ["python", "app/routes.py"]
