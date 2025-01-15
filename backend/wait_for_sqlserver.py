import os
import time
import pyodbc

def wait_for_sql_server_and_init():
    server = os.getenv("SQL_SERVER")
    port = os.getenv("SQL_PORT")
    username = os.getenv("DBUID")
    password = os.getenv("DBPWD")
    init_completed_file = "/var/shared/init_completed.txt"  # Shared volume path

    retries = 10
    while retries > 0:
        try:
            # Check SQL Server connection
            connection = pyodbc.connect(
                f"DRIVER={{ODBC Driver 17 for SQL Server}};"
                f"SERVER={server},{port};"
                f"UID={username};"
                f"PWD={password};"
                f"DATABASE=master"
            )
            connection.close()
            print("SQL Server is ready!")

            # Check if the init.sql has completed
            if os.path.exists(init_completed_file):
                print("Initialization completed!")
                return
            else:
                print("Initialization not yet completed. Waiting...")
        except Exception as e:
            print(f"Waiting for SQL Server to be ready... ({e})")

        retries -= 1
        time.sleep(5)

    raise Exception("SQL Server or initialization failed after multiple retries!")

if __name__ == "__main__":
    wait_for_sql_server_and_init()
