#!/bin/bash

LOG_DIR="/var/log/sqlscripts"
mkdir -p $LOG_DIR

LOG_FILE="$LOG_DIR/execute-sql-scripts.log"
ROLLBACK_LOG_FILE="$LOG_DIR/rollback-sql-scripts.log"

echo "Executing SQL scripts in Sprint Folder: ${SPRINT_FOLDER}..." | tee -a $LOG_FILE
cd /var/opt/sqlserver/db/${SPRINT_FOLDER}/Exec || exit 1

EXECUTED_SCRIPTS=()

for file in *.sql; do
  echo "Executing $file..." | tee -a $LOG_FILE
  SCRIPT_NAME=$(basename "$file")
  
  # Check if the script has already been executed
  SCRIPT_COMPLETED=$(ACCEPT_EULA=Y /opt/mssql-tools/bin/sqlcmd -S localhost -U "$DB_UID" -P "$SA_PASSWORD" -d "$DB_NAME" -Q "SET NOCOUNT ON; SELECT COUNT(1) FROM ExecutedScripts WHERE ScriptName = '$SCRIPT_NAME'" -h -1 | tr -d '\r\n[:space:]')

  if [ "$SCRIPT_COMPLETED" -eq 0 ]; then
    ACCEPT_EULA=Y /opt/mssql-tools/bin/sqlcmd -S localhost -U ${DB_UID} -P ${SA_PASSWORD} -d ${DB_NAME} -i "$file" 2>> $LOG_FILE
    SQL_EXIT_CODE=$? | tee -a $LOG_FILE

    if [ $SQL_EXIT_CODE -eq 0 ]; then
      echo "Logging success for $SCRIPT_NAME..." | tee -a $LOG_FILE
      ACCEPT_EULA=Y /opt/mssql-tools/bin/sqlcmd -S localhost -U ${DB_UID} -P ${SA_PASSWORD} -d ${DB_NAME} -Q "INSERT INTO ExecutedScripts (ScriptName, Status) VALUES ('$SCRIPT_NAME', 'Success')" 2>> $LOG_FILE
      EXECUTED_SCRIPTS+=("$SCRIPT_NAME")
    else
      echo "Script $SCRIPT_NAME failed with exit code $SQL_EXIT_CODE. Initiating rollback..." | tee -a $LOG_FILE
      
      # Trigger rollback
      cd ../Rollback || exit 1
      for executed_script in $(printf "%s\n" "${EXECUTED_SCRIPTS[@]}" | tac); do
        ROLLBACK_FILE="${executed_script}"
        if [ -f "$ROLLBACK_FILE" ]; then
          echo "Rolling back $ROLLBACK_FILE..." | tee -a $ROLLBACK_LOG_FILE
          ACCEPT_EULA=Y /opt/mssql-tools/bin/sqlcmd -S localhost -U ${DB_UID} -P ${SA_PASSWORD} -d ${DB_NAME} -i "$ROLLBACK_FILE" 2>> $ROLLBACK_LOG_FILE
        else
          echo "Rollback script not found for $ROLLBACK_FILE." | tee -a $ROLLBACK_LOG_FILE
        fi
      done
      echo "Rollback complete. Exiting with failure." | tee -a $LOG_FILE
      exit 1  # Mark failure after rollback
    fi
  else
    echo "Skipping already executed script: $SCRIPT_NAME" | tee -a $LOG_FILE
  fi
done

echo "All scripts executed successfully!" | tee -a $LOG_FILE
exit 0
