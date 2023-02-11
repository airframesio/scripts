#!/usr/bin/env bash
#
# Airframes Installer - Common functions
#

STEP=$((100/$STEPS))
current_step=0
LOG_FILE="/tmp/airframes-installer/logs/acarsdec.log"

printStep() {
  (
    cat <<EOF
XXX
$counter
$counter% installed

$1
XXX
EOF
  ) | dialog --title "Installing acarsdec" --gauge "Initializing" 10 70 0
}

doStep() {
  printStep "${@:2}"
  if [ $1 == "done" ]; then
    return 0
  fi
  $1 >> $LOG_FILE 2>&1
  ((current_step+=1))
  ((counter+=STEP))
}
