#!/usr/bin/env bash
#
# Airframes Installer
# https://github.com/airframesio/scripts/installer/installer.sh
#
# This script installs the Airframes-related decoder clients & sets up the feeds.
#
# Usage:
#
#   Quick and easy
#
#   $ curl -s https://raw.githubusercontent.com/airframesio/scripts/master/installer/installer.sh | sudo bash
#
#   Or, if you prefer to download the script first
#
#   $ curl -s -o install.sh https://raw.githubusercontent.com/airframesio/scripts/master/installer/installer.sh
#   $ sudo ./install.sh
#
#   Or, if you prefer to clone the repo first
#
#   $ git clone https://github.com/airframesio/scripts.git
#   $ cd scripts/installer
#   $ sudo ./installer.sh
#

# Exit on error
# set -e

# Enforce that this script is run as root
# if [ "$(id -u)" != "0" ]; then
#   echo "This script must be run as root. Rerun with sudo!" 1>&2
#   exit 1
# fi

### Variables

exec 3>&1

version="0.1.0"
title="Airframes Installer ${version}"

### Functions: System

function platform() {
  local platform=$(uname -s)
  echo "$platform"
}

function platformSupported() {
  local platform=$(platform)
  if [ "$platform" == "Linux" ]; then
    return 0
  elif [ "$platform" == "Darwin" ]; then
    return 0
  else
    return 1
  fi
}

### Functions: Support

function installPlatformDependencies() {
  local platform=$(platform)
  if [ "$platform" == "Linux" ]; then
    apt-get update
    apt-get install -y git dialog
  elif [ "$platform" == "Darwin" ]; then
    brew install git dialog
  fi
}

function showPlatformNotSupported() {
  local platform=$(platform)
  dialog --title "$title" \
    --msgbox "Your platform ($platform) is not supported." 10 50
}

### Functions: Menus

function showMenuMain() {
  local result=$(dialog --title "$title" \
    --cancel-label "Exit" \
    --menu "Choose an option:" 15 50 3 \
    1 "Install" \
    2 "Detect SDRs" \
    3 "Configure SDR assignments" \
    4 "Configure feeds" \
    5 "Health check" 2>&1 1>&3)
  echo "$result"
}

function showMenuInstall() {
  local result=$(dialog --title "$title" \
    --cancel-label "Back" \
    --menu "Choose an option:" 15 50 3 \
    1 "Install by compiling" \
    2 "Install with Docker" \
    3 "Install with packages" \
    2>&1 1>&3)
  echo "$result"
}

function showMenuInstallDockerApps() {
  local result=$(dialog --title "$title" \
  --ok-label "Install" \
  --cancel-label "Back" \
  --checklist "Select Docker apps to install:" 15 50 8 \
  1 "acarsdec" "on" \
  2 "acarshub" "on" \
  3 "dumphfdl" "off" \
  4 "dumpvdl2" "on" \
  5 "vdlm2dec" "off" 2>&1 1>&3)
  echo "$result"
}

function showMenuInstallDecoders() {
  local result=$(dialog --title "$title" \
  --ok-label "Install" \
  --cancel-label "Back" \
  --checklist "Select decoders to install:" 15 50 8 \
  1 "acarsdec" "on" \
  2 "dumphfdl" "off" \
  3 "dumpvdl2" "on" \
  4 "vdlm2dec" "off" 2>&1 1>&3)
  echo "$result"
}

function showMenuConfigureFeeds() {
  local result=$(dialog --title "$title" \
    --cancel-label "Back" \
    --menu "Choose an option:" 10 50 3 \
    1 "Configure with Docker" \
    2 "Configure with packages" \
    3 "Configure by compiling" 2>&1 1>&3)
  echo "$result"
}

function installManualAcarsdec() {
  echo "Installing acarsdec"
  # dialog --infobox "Installing acarsdec" 3 50
  # curl -s https://raw.githubusercontent.com/airframesio/scripts/master/installer/decoders/compile/install/acarsdec.sh | bash
  $(pwd)/decoders/compile/install/acarsdec.sh
}



### Main

platformSupported
if [ $? -ne 0 ]; then
  showPlatformNotSupported
  exit 1
fi

installPlatformDependencies

while [ $? -ne 1 ]
do
  result=$(showMenuMain)
  case $result in
  1)
  result=$(showMenuInstall)

  if [ "$result" = "1" ]; then
    selections=$(showMenuInstallDecoders)
    for selection in $selections
    do
      case $selection in
      1)
      sudo installManualAcarsdec
      if [ $? -ne 0 ]; then
        dialog --title "Error" --msgbox "acarsdec failed to install" 6 50
      fi
      sleep 1
      ;;
      2)
      echo "Installing dumphfdl"
      sudo installManualDumphfdl
      if [ $? -ne 0 ]; then
        dialog --title "Error" --msgbox "dumphfdl failed to install" 6 50
      fi
      sleep 1
      ;;
      3)
      echo "Installing dumpvdl2"
      sudo installManualDumphvdl2
      if [ $? -ne 0 ]; then
        dialog --title "Error" --msgbox "dumpvdl2 failed to install" 6 50
      fi
      sleep 1
      ;;
      4)
      echo "Installing vdlm2dec"
      sudo installManualVdlm2dec
      if [ $? -ne 0 ]; then
        dialog --title "Error" --msgbox "vdlm2dec failed to install" 6 50
      fi
      sleep 1
      ;;
      esac
    done
  fi

  if [ "$result" = "2" ]; then
    selections=$(showMenuInstallDockerApps)
  fi

  if [ "$result" = "3" ]; then
    echo "Installing with packages"
  fi


  esac
done


echo " "
echo "Thank you for feeding!"

# Exit with success
exit 0
