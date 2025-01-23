#!/bin/bash lf

SPRINT_FOLDER=$1
DBUID=$2
DBPWD=$3
DATABASE=$4

echo "Starting SQL script execution in Sprint Folder: $SPRINT_FOLDER"

for file in /var/opt/sqlserver/db/${SPRINT_FOLDER}/Exec/*.sql; do
    SCRIPT_NAME=$(basename $file)
    echo "Checking if $SCRIPT_NAME has already been executed..."

    EXISTS=$(/opt/mssql-tools/bin/sqlcmd -S localhost -U $DBUID -P $DBPWD -d $DATABASE -Q "SELECT COUNT(1) FROM ExecutedScripts WHERE ScriptName = '$SCRIPT_NAME'" -h -1)

    echo "Result of EXISTS query: $EXISTS"

    if [ "$EXISTS" -eq 0 ]; then
        echo "Executing $SCRIPT_NAME..."
        /opt/mssql-tools/bin/sqlcmd -S localhost -U $DBUID -P $DBPWD -d $DATABASE -i $file
        if [ $? -eq 0 ]; then
            echo "Logging success for $SCRIPT_NAME..."
            /opt/mssql-tools/bin/sqlcmd -S localhost -U $DBUID -P $DBPWD -d $DATABASE -Q "INSERT INTO ExecutedScripts (ScriptName, Status) VALUES ('$SCRIPT_NAME', 'Success')"
        else
            echo "Logging failure for $SCRIPT_NAME..."
            /opt/mssql-tools/bin/sqlcmd -S localhost -U $DBUID -P $DBPWD -d $DATABASE -Q "INSERT INTO ExecutedScripts (ScriptName, Status) VALUES ('$SCRIPT_NAME', 'Failure')"
            exit 1
        fi
    else
        echo "Skipping already executed script: $SCRIPT_NAME"
    fi
done

echo "All SQL scripts processed."
