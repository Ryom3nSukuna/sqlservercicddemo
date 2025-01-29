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
  
  # Check if the script has already been executed.
  SCRIPT_STATUS=$(ACCEPT_EULA=Y /opt/mssql-tools/bin/sqlcmd -S localhost -U "$DB_UID" -P "$SA_PASSWORD" -d "$DB_NAME" -Q "SET NOCOUNT ON; SELECT Status FROM ExecutedScripts WHERE ScriptName = '$SCRIPT_NAME'" -h -1 | tr -d '\r\n[:space:]')

  if [[ "$SCRIPT_STATUS" != "Success" && "$SCRIPT_STATUS" != "Rolled Back" ]]; then
    START_TIME=$(date +"%Y-%m-%d %H:%M:%S")
    ERROR_OUTPUT=$(
      ACCEPT_EULA=Y /opt/mssql-tools/bin/sqlcmd -S localhost -U ${DB_UID} -P ${SA_PASSWORD} -d ${DB_NAME} -i "$file" -b 2>&1
    )
    SQL_EXIT_CODE=$?
	echo "ERROR_OUTPUT: $ERROR_OUTPUT"
	echo "SQL_EXIT_CODE: $SQL_EXIT_CODE"
	
    if [ $SQL_EXIT_CODE -eq 0 ]; then
      echo "Logging success for $SCRIPT_NAME..." | tee -a $LOG_FILE
	  NEXT_SCRID=$(
					ACCEPT_EULA=Y /opt/mssql-tools/bin/sqlcmd -S localhost -U ${DB_UID} -P ${SA_PASSWORD} -d ${DB_NAME} -h -1 -Q "
						SET NOCOUNT ON; SELECT ISNULL(MAX(ScrID), 0) + 1 FROM ExecutedScripts
					" | tr -d '\r\n[:space:]'
				  )
	  echo "NEXT_SCRID: $NEXT_SCRID"
      ACCEPT_EULA=Y /opt/mssql-tools/bin/sqlcmd -S localhost -U ${DB_UID} -P ${SA_PASSWORD} -d ${DB_NAME} -Q "
        INSERT INTO ExecutedScripts (ScrID, ScriptName, Status, ExecutionTime)
        VALUES ($NEXT_SCRID, '$SCRIPT_NAME', 'Success', '$START_TIME')" 2>> $LOG_FILE
      EXECUTED_SCRIPTS+=("$SCRIPT_NAME")
    else
      ERROR_DETAILS=$(echo "$ERROR_OUTPUT" | awk '/Msg [0-9]+/{msg=$0; getline; print msg "\n" $0}' | tr '\n' ' ' | sed "s/'/''/g")
	  echo "ERROR_DETAILS: $ERROR_DETAILS"
      echo "Script $SCRIPT_NAME failed with exit code $SQL_EXIT_CODE. Logging failure and initiating rollback..." | tee -a $LOG_FILE
	  NEXT_SCRID=$(
					ACCEPT_EULA=Y /opt/mssql-tools/bin/sqlcmd -S localhost -U ${DB_UID} -P ${SA_PASSWORD} -d ${DB_NAME} -h -1 -Q "
						SET NOCOUNT ON; SELECT ISNULL(MAX(ScrID), 0) + 1 FROM ExecutedScripts
					" | tr -d '\r\n[:space:]'
				  )
      echo "NEXT_SCRID: $NEXT_SCRID"
	  ACCEPT_EULA=Y /opt/mssql-tools/bin/sqlcmd -S localhost -U ${DB_UID} -P ${SA_PASSWORD} -d ${DB_NAME} -Q "
        INSERT INTO ExecutedScripts (ScrID, ScriptName, Status, ExecutionTime, ErrorDetails)
        VALUES ($NEXT_SCRID, '$SCRIPT_NAME', 'Failed', '$START_TIME', '$ERROR_DETAILS')" 2>> $LOG_FILE

      # Trigger rollback
      cd ../Rollback || exit 1
      for executed_script in $(printf "%s\n" "${EXECUTED_SCRIPTS[@]}" | tac); do
        ROLLBACK_FILE="${executed_script}"
        if [ -f "$ROLLBACK_FILE" ]; then
          echo "Rolling back $ROLLBACK_FILE..." | tee -a $ROLLBACK_LOG_FILE
          ROLLBACK_START_TIME=$(date +"%Y-%m-%d %H:%M:%S")
          ROLLBACK_OUTPUT=$(ACCEPT_EULA=Y /opt/mssql-tools/bin/sqlcmd -S localhost -U ${DB_UID} -P ${SA_PASSWORD} -d ${DB_NAME} -i "$ROLLBACK_FILE" -b 2>&1)
          ROLLBACK_EXIT_CODE=$?

          if [ $ROLLBACK_EXIT_CODE -eq 0 ]; then
            ACCEPT_EULA=Y /opt/mssql-tools/bin/sqlcmd -S localhost -U ${DB_UID} -P ${SA_PASSWORD} -d ${DB_NAME} -Q "
              UPDATE ExecutedScripts
              SET Status = 'Rolled Back', RollbackTime = '$ROLLBACK_START_TIME'
              WHERE ScriptName = '$ROLLBACK_FILE'" 2>> $ROLLBACK_LOG_FILE
          else
            echo "Rollback for $ROLLBACK_FILE failed with exit code $ROLLBACK_EXIT_CODE." | tee -a $ROLLBACK_LOG_FILE
          fi
        else
          echo "Rollback script not found for $ROLLBACK_FILE." | tee -a $ROLLBACK_LOG_FILE
        fi
      done
      echo "Rollback complete. Exiting with failure." | tee -a $LOG_FILE
      exit 1  # Mark failure after rollback
    fi
  else
    echo "Skipping already executed script: $SCRIPT_NAME with status $SCRIPT_STATUS" | tee -a $LOG_FILE
  fi
done

echo "All scripts executed successfully!" | tee -a $LOG_FILE
exit 0
