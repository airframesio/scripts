#!/usr/bin/env bash
#
# Airframes Installer - dumpvdl2 by szpajder (VDL decoder)
# https://github.com/airframesio/scripts/installer/decoders/install-acarsdec.sh
#

# Exit on error
# set -e

mkdir -p /tmp/airframes-installer/src
git clone https://github.com/szpajder/dumpvdl2.git /tmp/airframes-installer/src/dumpvdl2

cd /tmp/airframes-installer/src/dumpvdl2
mkdir build
cd build
cmake ..
sudo make install

rm -rf /tmp/airframes-installer/src/dumpvdl2
