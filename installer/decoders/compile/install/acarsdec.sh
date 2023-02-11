#!/usr/bin/env bash
#
# Airframes Installer - acarsdec by TLeconte (ACARS decoder)
# https://github.com/airframesio/scripts/installer/decoders/install-acarsdec.sh
#

# Exit on error
# set -e

STEPS=4
STEP=$((100/$STEPS))
current_step=0
LOG_FILE="/tmp/airframes-installer/logs/acarsdec.log"

srcInit() {
  mkdir -p /tmp/airframes-installer/src
  mkdir -p /tmp/airframes-installer/logs
  rm -rf /tmp/airframes-installer/src/acarsdec
  rm -rf /tmp/airframes-installer/src/libacars
}

installDeps() {
  apt-get update
  apt-get install -y git build-essential librtlsdr-dev libusb-1.0-0-dev libmirisdr-dev libairspy-dev cmake zlib1g-dev libxml2-dev libsndfile-dev
}

checkout() {
  git clone https://github.com/TLeconte/acarsdec.git /tmp/airframes-installer/src/acarsdec
  git clone https://github.com/szpajder/libacars.git /tmp/airframes-installer/src/libacars
}

build() {
  cd /tmp/airframes-installer/src/libacars
  mkdir build
  cd build
  cmake ..
  make install
  ldconfig

  cd /tmp/airframes-installer/src/acarsdec
  mkdir build
  cd build
  cmake .. -Drtl=ON
  make install
}

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

printStep "Initializing"
srcInit >> $LOG_FILE 2>&1
((counter+=STEP))

printStep "Installing dependencies"
installDeps >> $LOG_FILE 2>&1
((current_step=1))
((counter+=STEP))

printStep "Checking out source code"
checkout >> $LOG_FILE 2>&1
((current_step=2))
((counter+=STEP))

printStep "Building"
build >> $LOG_FILE 2>&1
((current_step=3))
((counter+=STEP))

printStep "Done"
