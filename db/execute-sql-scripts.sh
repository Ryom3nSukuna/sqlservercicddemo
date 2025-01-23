#!/bin/bash

# Print received variables for debugging
echo "ISPRINT_FOLDER=${ISPRINT_FOLDER}"
echo "IDATABASE=${IDATABASE}"
echo "IDBUID=${IDBUID}"
echo "IDBPWD=${IDBPWD}"

echo "Executing SQL scripts in Sprint Folder: ${ISPRINT_FOLDER}..."
echo "Connecting to database ${IDATABASE} with user ${IDBUID}."

# Navigate to the correct directory
cd /var/opt/sqlserver/db/"${ISPRINT_FOLDER}"/Exec || {
    echo "Directory /var/opt/sqlserver/db/${ISPRINT_FOLDER}/Exec does not exist."
    exit 1
}

# Execute all .sql scripts
for sql_file in *.sql; do
    echo "Executing ${sql_file}..."
    /opt/mssql-tools/bin/sqlcmd -S localhost -U "${IDBUID}" -P "${IDBPWD}" -d "${IDATABASE}" -i "${sql_file}"
    if [ $? -eq 0 ]; then
        echo "Successfully executed ${sql_file}"
    else
        echo "Failed to execute ${sql_file}" >&2
        exit 1
    fi
done
