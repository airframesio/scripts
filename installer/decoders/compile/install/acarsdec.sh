#!/usr/bin/env bash
#
# Airframes Installer - acarsdec by TLeconte (ACARS decoder)
# https://github.com/airframesio/scripts/installer/decoders/install-acarsdec.sh
#

# Exit on error
# set -e

STEPS=8
STEP=$((100/$STEPS))
current_step=0

COMMANDS=(
  "mkdir -p /tmp/airframes-installer/src"
  "mkdir -p /tmp/airframes-installer/logs"
  "rm -rf /tmp/airframes-installer/src/acarsdec"
  "git clone https://github.com/TLeconte/acarsdec.git /tmp/airframes-installer/src/acarsdec"
  "cd /tmp/airframes-installer/src/acarsdec"
  "mkdir build"
  "cd build"
  "cmake .."
  "make install"
)

(
  while true; do
    cat <<EOF
XXX
$counter
$counter% installed

$COMMAND
XXX
EOF
    COMMAND="${COMMANDS[$current_step]}"
    [[ $STEPS -lt $current_step ]] && "$COMMAND &> /tmp/airframes-installer/logs/acarsdec.log"
    ((current_step += 1))
    ((counter += STEP))
    [[ $counter -gt 100 ]] && break
    sleep 1
  done
) | dialog --title "Installing acarsdec" --gauge "Installing acarsdec" 10 70 0
