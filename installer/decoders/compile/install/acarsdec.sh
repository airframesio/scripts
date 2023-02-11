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

prepare() {
  mkdir -p /tmp/airframes-installer/src
  mkdir -p /tmp/airframes-installer/logs
  rm -rf /tmp/airframes-installer/src/acarsdec
  rm -rf /tmp/airframes-installer/src/libacars
}

dependencies() {
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

doStep() {
  printStep "${@:2}"
  if [ $1 == "done" ]; then
    return 0
  fi
  $1 >> $LOG_FILE 2>&1
  ((current_step+=1))
  ((counter+=STEP))
}

doStep "prepare" "Preparing"
doStep "dependencies" "Installing dependencies"
doStep "checkout" "Checking out source code"
doStep "build" "Building"
doStep "done" "Done"
