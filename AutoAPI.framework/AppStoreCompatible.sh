#!/bin/sh

#  AppStoreCompatible.sh
#
#  Created by Mikk Rätsep on 07/03/2017.
#


# This script thins the Universal (library) file
# Also removes the irrelevant .swiftmodule-s by removing the Simulator parts


# How to use AppStoreCompatible.sh script:
#   1) navigate to the .framework folder in terminal
#   2) execute
#       sh AppStoreCompatible.sh




# Make some vars
FILE_COUNT=0


# Ignores the macOS platform - there's no simulator on it...
if [ "${PLATFORM_NAME}" != "macosx" ]; then


# See if this is called from XCode or not
if [ -n "${SCRIPT_INPUT_FILE_COUNT}" ]; then

FILE_COUNT="${SCRIPT_INPUT_FILE_COUNT}"
FRAMEWORK_PATH="${SCRIPT_INPUT_FILE_0}"

else

FILE_COUNT=1
FRAMEWORK_PATH="$(pwd)"

fi



# Check there's an input file
if [ ${FILE_COUNT} -eq 1 ]; then


# Gather some paths
NAME=${FRAMEWORK_PATH##*"/"}
NAME=${NAME%%".framework"}

MODULES_DIR="${FRAMEWORK_PATH}/Modules/${NAME}.swiftmodule"

# Remove the i386 slices from the binary
if $(lipo ${NAME} -verify_arch i386); then

lipo ${NAME} -remove i386 -o ${NAME}

fi

# Remove the .swiftmodule files
rm -fr "${MODULES_DIR}/i386.swiftdoc"
rm -fr "${MODULES_DIR}/i386.swiftmodule"


# Remove the x86_64 slices from the binary and files from the .swiftmodule
if $(lipo ${NAME} -verify_arch x86_64); then

lipo ${NAME} -remove x86_64 -o ${NAME}

fi

# Remove the .swiftmodule files
rm -fr "${MODULES_DIR}/x86_64.swiftdoc"
rm -fr "${MODULES_DIR}/x86_64.swiftmodule"

# Remove the script (can't upload to iTunesConnect with it)
rm -- "$0"

fi


fi
