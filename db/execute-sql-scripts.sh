#!/bin/bash

echo "Executing SQL scripts in Sprint Folder: "$SPRINT_FOLDER"..."
cd /var/opt/sqlserver/db/"$SPRINT_FOLDER"/Exec || exit 1

for file in *.sql; do
  echo "Executing $file..."
  /opt/mssql-tools/bin/sqlcmd -S localhost -U "$DB_UID" -P "$SA_PASSWORD" -d "$DB_NAME" -i "$file"
  if [ $? -eq 0 ]; then
    echo "Success: $file"
  else
    echo "Failure: $file"
    exit 1
  fi
done
