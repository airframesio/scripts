#!/usr/bin/env bash
#
# Airframes Installer - acarsdec by TLeconte (ACARS decoder)
# https://github.com/airframesio/scripts/installer/decoders/install-acarsdec.sh
#

# Exit on error
# set -e

STEPS=4

source $(dirname -- "$0")/../../../utils/common.sh

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

doStep "prepare" "Preparing"
doStep "dependencies" "Installing dependencies"
doStep "checkout" "Checking out source code"
doStep "build" "Building"
doStep "done" "Done"
