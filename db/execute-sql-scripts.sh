#!/bin/bash

# Capture arguments from the command line
for arg in "$@"
do
    eval "$arg"
done

echo "Executing SQL scripts in Sprint Folder: $SPRINT_FOLDER..."
echo "Connecting to database $DATABASE with user $DBUID."

# Navigate to the correct directory
cd /var/opt/sqlserver/db/$SPRINT_FOLDER/Exec || exit

# Iterate over .sql files and execute
for sql_file in *.sql; do
    echo "Executing $sql_file..."
    /opt/mssql-tools/bin/sqlcmd -S localhost -U "$DBUID" -P "$DBPWD" -d "$DATABASE" -i "$sql_file"
    if [ $? -eq 0 ]; then
        echo "Successfully executed $sql_file"
    else
        echo "Failed to execute $sql_file" >&2
        exit 1
    fi
done
