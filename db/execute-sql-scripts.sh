#!/bin/bash

# Print received variables for debugging
echo "SPRINT_FOLDER=${SPRINT_FOLDER}"
echo "DATA-BASE=${DATA-BASE}"
echo "DB-UID=${DB-UID}"
echo "DB-PWD=${DB-PWD}"

echo "Executing SQL scripts in Sprint Folder: ${SPRINT_FOLDER}..."
echo "Connecting to database ${DATABASE} with user ${DBUID}."

# Navigate to the correct directory
cd /var/opt/sqlserver/db/${SPRINT_FOLDER}/Exec || {
    echo "Directory /var/opt/sqlserver/db/${SPRINT_FOLDER}/Exec does not exist."
    exit 1
}

# Execute all .sql scripts
for sql_file in *.sql; do
    echo "Executing ${sql_file}..."
    /opt/mssql-tools/bin/sqlcmd -S localhost -U "${DB-UID}" -P "${DB-PWD}" -d "${DATA-BASE}" -i "${sql_file}"
    if [ $? -eq 0 ]; then
        echo "Successfully executed ${sql_file}"
    else
        echo "Failed to execute ${sql_file}" >&2
        exit 1
    fi
done
