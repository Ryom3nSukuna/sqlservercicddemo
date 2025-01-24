#!/bin/bash

echo "Executing SQL scripts in Sprint Folder: ${SPRINT_FOLDER}..."
cd /var/opt/sqlserver/db/${SPRINT_FOLDER}/Exec || exit 1

for file in *.sql; do
  echo "Executing $file..."
  SCRIPT_NAME=$(basename "$file")
  
  echo "Checking if $SCRIPT_NAME has already been executed..."
  
  # Check if the script is logged in the ExecutedScripts table
  SCRIPT_COMPLETED=$(ACCEPT_EULA=Y /opt/mssql-tools/bin/sqlcmd -S localhost -U "$DB_UID" -P "$SA_PASSWORD" -d "$DB_NAME" -Q "SELECT COUNT(1) FROM ExecutedScripts WHERE ScriptName = '$SCRIPT_NAME'" -h -1)

  if [ "$SCRIPT_COMPLETED" -eq 0 ]; then
    echo "Executing $SCRIPT_NAME..."
	ACCEPT_EULA=Y /opt/mssql-tools/bin/sqlcmd -S localhost -U ${DB_UID} -P ${SA_PASSWORD} -d ${DB_NAME} -i "$file"
	
	if [ $? -eq 0 ]; then
		echo "Logging success for $SCRIPT_NAME..."
		ACCEPT_EULA=Y /opt/mssql-tools/bin/sqlcmd -S localhost -U ${DB_UID} -P ${SA_PASSWORD} -d ${DB_NAME} -Q "INSERT INTO ExecutedScripts (ScriptName, Status) VALUES ('$SCRIPT_NAME', 'Success')"
    else
		echo "Logging failure for $SCRIPT_NAME..."
		ACCEPT_EULA=Y /opt/mssql-tools/bin/sqlcmd -S localhost -U ${DB_UID} -P ${SA_PASSWORD} -d ${DB_NAME} -Q "INSERT INTO ExecutedScripts (ScriptName, Status) VALUES ('$SCRIPT_NAME', 'Failure')"
		exit 1
	fi
  else
    echo "Skipping already executed script: $SCRIPT_NAME"
  fi
done
