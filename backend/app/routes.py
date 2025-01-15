import os
import pyodbc
import time
from flask import Flask, make_response, request  # Import make_response from Flask

app = Flask(__name__)

# Database connection string
def get_db_connection():
    retries = 5
    while retries > 0:
        try:
            server = os.getenv("SQL_SERVER")
            port = os.getenv("SQL_PORT")
            database = os.getenv("DATABASE")
            username = os.getenv("DBUID")
            password = os.getenv("DBPWD")
            
            # Log connection details
            app.logger.info(f"Connecting to SQL Server: {server}:{port}, Database: {database}, User: {username}")

            # Attempt connection
            connection = pyodbc.connect(
                f"DRIVER={{ODBC Driver 17 for SQL Server}};"
                f"SERVER={server},{port};"
                f"DATABASE={database};"
                f"UID={username};"
                f"PWD={password}"
            )
            return connection
        except Exception as e:
            app.logger.error(f"Database connection failed: {e}. Retrying...")
            retries -= 1
            time.sleep(5)

    raise Exception("Database connection failed after multiple retries!")

@app.route("/")
def home():
    try:
        conn = get_db_connection()
        conn.close()
        response = f"Connected to {os.getenv('DATABASE')} on {os.getenv('SQL_SERVER')}:{os.getenv('SQL_PORT')} successfully!"
        resp = make_response(response)
        resp.headers["Content-Type"] = "text/plain"
        return resp
    except Exception as e:
        error = f"Failed to connect to database: {str(e)}"
        app.logger.error(error, exc_info=True)
        resp = make_response(error, 500)
        resp.headers["Content-Type"] = "text/plain"
        return resp

@app.route("/health")
def health():
    return "Flask app is running!", 200

if __name__ == "__main__":
    # Add a delay before starting the Flask app
    time.sleep(15)  # Wait 15 seconds to ensure SQL Server is ready
    app.run(
        debug=os.getenv("FLASK_ENV") == "development",
        host="0.0.0.0",
        port=int(os.getenv("APP_PORT",5000))  # Port is entirely driven by .env
    )

@app.before_request
def log_request_info():
    app.logger.debug(f"Request from: {request.remote_addr}, Method: {request.method}, Path: {request.path}")
