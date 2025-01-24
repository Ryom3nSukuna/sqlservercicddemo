#!/bin/bash

# Function to check if SQL Server is ready
wait_for_sqlserver() {
    echo "Waiting for SQL Server to be ready..."
    until /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "${SA_PASSWORD}" -Q "SELECT 1" > /dev/null 2>&1; do
        sleep 5
        echo "SQL Server is not ready yet. Retrying..."
    done
    echo "SQL Server is ready!"
}

# Start SQL Server in the background
/opt/mssql/bin/sqlservr &

# Wait for SQL Server to be ready
wait_for_sqlserver

# Execute the specific initialization script
if [ -n "$INIT_SQL_FILE" ] && [ -f "$INIT_SQL_FILE" ]; then
    echo "Running initialization script: $INIT_SQL_FILE"
    /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "${SA_PASSWORD}" -i "$INIT_SQL_FILE"
else
    echo "Initialization script not found or not specified!"
fi

# Signal that initialization is complete
echo "INIT_COMPLETED" > /var/shared/init_completed.txt

# Wait for SQL Server process to finish
wait