#!/bin/bash

# Print received variables for debugging
echo "SPRINT_FOLDER=${SPRINT_FOLDER}"
echo "DATABASE=${DATABASE}"
echo "DBUID=${DBUID}"
echo "DBPWD=${DBPWD}"

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
    /opt/mssql-tools/bin/sqlcmd -S localhost -U "${DBUID}" -P "${DBPWD}" -d "${DATABASE}" -i "${sql_file}"
    if [ $? -eq 0 ]; then
        echo "Successfully executed ${sql_file}"
    else
        echo "Failed to execute ${sql_file}" >&2
        exit 1
    fi
done
