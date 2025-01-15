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

# Execute initialization scripts
echo "Executing SQL scripts from /docker-entrypoint-initdb.d"
for script in /docker-entrypoint-initdb.d/**/*.sql; do
    if [[ -f "$script" ]]; then
        echo "Running $script..."
        /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "${SA_PASSWORD}" -i "$script"
    fi
done

# Signal that initialization is complete
echo "INIT_COMPLETED" > /var/shared/init_completed.txt

# Wait for SQL Server process to finish
wait
