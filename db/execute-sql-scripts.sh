#!/bin/bash

echo "Executing SQL scripts in Sprint Folder: ${SPRINT_FOLDER}..."
cd /var/opt/sqlserver/db/${SPRINT_FOLDER}/Exec || exit 1

# Array to track successfully executed scripts
EXECUTED_SCRIPTS=()

for file in *.sql; do
  echo "Executing $file..."
  SCRIPT_NAME=$(basename "$file")
  
  echo "Checking if $SCRIPT_NAME has already been executed..."
  SCRIPT_COMPLETED=$(ACCEPT_EULA=Y /opt/mssql-tools/bin/sqlcmd -S localhost -U "$DB_UID" -P "$SA_PASSWORD" -d "$DB_NAME" -Q "SET NOCOUNT ON; SELECT COUNT(1) FROM ExecutedScripts WHERE ScriptName = '$SCRIPT_NAME'" -h -1 | tr -d '\r\n[:space:]')

  if [ "$SCRIPT_COMPLETED" -eq 0 ]; then
    echo "Executing $SCRIPT_NAME..."
    ACCEPT_EULA=Y /opt/mssql-tools/bin/sqlcmd -S localhost -U ${DB_UID} -P ${SA_PASSWORD} -d ${DB_NAME} -i "$file"
    
    if [ $? -eq 0 ]; then
      echo "Logging success for $SCRIPT_NAME..."
      ACCEPT_EULA=Y /opt/mssql-tools/bin/sqlcmd -S localhost -U ${DB_UID} -P ${SA_PASSWORD} -d ${DB_NAME} -Q "INSERT INTO ExecutedScripts (ScriptName, Status) VALUES ('$SCRIPT_NAME', 'Success')"
      EXECUTED_SCRIPTS+=("$SCRIPT_NAME")
    else
      echo "Script $SCRIPT_NAME failed. Initiating rollback..."
      
      # Rollback already executed scripts in reverse order
      cd ../Rollback || exit 1
      for executed_script in "${EXECUTED_SCRIPTS[@]}"; do
        ROLLBACK_FILE="${executed_script}"
        if [ -f "$ROLLBACK_FILE" ]; then
          echo "Executing rollback: $ROLLBACK_FILE..."
          ACCEPT_EULA=Y /opt/mssql-tools/bin/sqlcmd -S localhost -U ${DB_UID} -P ${SA_PASSWORD} -d ${DB_NAME} -i "$ROLLBACK_FILE"
          if [ $? -eq 0 ]; then
            echo "Rollback success for $executed_script."
          else
            echo "Rollback failed for $executed_script."
          fi
        else
          echo "Rollback script $ROLLBACK_FILE not found."
        fi
      done
      exit 1
    fi
  else
    echo "Skipping already executed script: $SCRIPT_NAME"
  fi
done
