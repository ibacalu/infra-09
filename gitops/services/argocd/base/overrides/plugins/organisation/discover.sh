#!/bin/bash

LOGFILE="/tmp/${ARGOCD_APP_NAME:-undefined}.org.discover.log"
truncate -s 0 "$LOGFILE"

# Log some information
{ date; pwd; ls -lah; } >> "$LOGFILE"

required_files=( ".organisation" )
avoided_files=( )

for i in "${avoided_files[@]}"; do
  if [ -f "$i" ]; then
    echo "WARN: $i is avoided" >> "$LOGFILE"
    echo "WARN: Application '${ARGOCD_APP_NAME}' does not use organisation plugin. Sent logs to ${LOGFILE}"
    exit 1
  fi
done

for i in "${required_files[@]}"; do
  if [ ! -f "$i" ]; then
    echo "WARN: $i is required" >> "$LOGFILE"
    echo "WARN: Application '${ARGOCD_APP_NAME}' does not use organisation plugin. Sent logs to ${LOGFILE}"
    exit 1
  fi
done

echo "INFO: Application '${ARGOCD_APP_NAME}' uses organisation plugin." >> "$LOGFILE"
echo "INFO: Completed"
exit 0
