#!/bin/bash
# Version: 1.2
# Date: 2020-12-21
# This bash script generates a CMSIS Software Pack:
#
# Pre-requisites:
# - bash shell (for Windows: install git for Windows)
# - 7z in path (zip archiving utility)
#   e.g. Ubuntu: sudo apt-get install p7zip-full p7zip-rar)
# - PackChk is taken from latest install CMSIS Pack installed in $CMSIS_PACK_ROOT
# - xmllint in path (XML schema validation; available only for Linux)

# Upstream repository
UPSTREAM_URL=https://api.github.com/repos/eclipse/paho.mqtt.embedded-c
#UPSTREAM_TAG=v1.1.0
UPSTREAM_TAG=29ab2aa

# Contributions merge
CONTRIB_MERGE=./contributions/merge
# Contributions additional folders/files
CONTRIB_ADD=./contributions/add

############### EDIT BELOW ###############
# Extend Path environment variable locally
#

OS=$(uname -s)
case $OS in
  'Linux')
    if [ -z ${CMSIS_PACK_ROOT+x} ] ; then
      CMSIS_PACK_ROOT="/home/$USER/.arm/Packs"
    fi
    CMSIS_TOOLSDIR="$(ls -drv ${CMSIS_PACK_ROOT}/ARM/CMSIS/* | head -1)/CMSIS/Utilities/Linux64"
    ;;
  'WindowsNT'|MINGW*|CYGWIN*)
    if [ -z ${CMSIS_PACK_ROOT+x} ] ; then
      CMSIS_PACK_ROOT="$LOCALAPPDATA/Arm/Packs"
    fi
    CMSIS_PACK_ROOT="/$(echo ${CMSIS_PACK_ROOT} | sed -e 's/\\/\//g' -e 's/://g' -e 's/\"//g')"
    CMSIS_TOOLSDIR="$(ls -drv ${CMSIS_PACK_ROOT}/ARM/CMSIS/* | head -1)/CMSIS/Utilities/Win32"
    ;;
  'Darwin') 
    echo "Error: CMSIS Tools not available for Mac at present."
    exit 1
    ;;
  *)
    echo "Error: unrecognized OS $OS"
    exit 1
    ;;
esac

PATH_TO_ADD="$CMSIS_TOOLSDIR"

[[ ":$PATH:" != *":$PATH_TO_ADD}:"* ]] && PATH="${PATH}:${PATH_TO_ADD}"
echo $PATH_TO_ADD appended to PATH
echo " "

# Pack warehouse directory - destination 
PACK_WAREHOUSE=./output

# Temporary pack build directory
PACK_BUILD=./build

############ DO NOT EDIT BELOW ###########
echo Starting CMSIS-Pack Generation: `date`
# Zip utility check 
ZIP=7z
type -a "${ZIP}"
errorlevel=$?
if [ $errorlevel -gt 0 ]
  then
  echo "Error: No 7zip Utility found"
  echo "Action: Add 7zip to your path"
  echo " "
  exit
fi

# Pack checking utility check
PACKCHK=PackChk
type -a ${PACKCHK}
errorlevel=$?
if [ $errorlevel != 0 ]
  then
  echo "Error: No PackChk Utility found"
  echo "Action: Add PackChk to your path"
  echo "Hint: Included in CMSIS Pack:"
  echo "$CMSIS_PACK_ROOT/ARM/CMSIS/<version>/CMSIS/Utilities/<os>/"
  echo " "
  exit
fi
echo " "

# Locate Package Description file
# check whether there is more than one pdsc file
pushd $CONTRIB_ADD
NUM_PDSCS=`ls -1 *.pdsc | wc -l`
PACK_DESCRIPTION_FILE=`ls *.pdsc`
popd
if [ ${NUM_PDSCS} -lt 1 ]
  then
  echo "Error: No *.pdsc file found in current directory"
  echo " "
  exit
elif [ ${NUM_PDSCS} -gt 1 ]
  then
  echo "Error: Only one PDSC file allowed in directory structure:"
  echo "Found:"
  echo "$PACK_DESCRIPTION_FILE"
  echo "Action: Delete unused pdsc files"
  echo " "
  exit
fi

SAVEIFS=$IFS
IFS=.
set ${PACK_DESCRIPTION_FILE}
# Pack Vendor
PACK_VENDOR=$1
# Pack Name
PACK_NAME=$2
echo "Generating Pack Version: for $PACK_VENDOR.$PACK_NAME"
echo " "
IFS=$SAVEIFS

#if $PACK_BUILD directory does not exist, create it.
if [ ! -d "$PACK_BUILD" ]; then
  mkdir -p "$PACK_BUILD"
  pushd $PACK_BUILD
  curl -L  $UPSTREAM_URL/tarball/$UPSTREAM_TAG | tar xz --strip=1
  popd
fi

# Merge contributions into $PACK_BUILD
# add (must not overwrite)
cp -vr $CONTRIB_ADD/* $PACK_BUILD/

# Merge (will overwrite existing files)
cp -vrf $CONTRIB_MERGE/* $PACK_BUILD/

# Build documentation
pushd $PACK_BUILD
doxygen doc/DoxyfileMQTTClient.in
rm -f   doc/DoxyfileMQTTClient.in
doxygen doc/DoxyfileMQTTClient-C.in
rm -f   doc/DoxyfileMQTTClient-C.in
doxygen doc/DoxyfileMQTTPacket.in
rm -f   doc/DoxyfileMQTTPacket.in
rm -f   doc/pahologo.png
popd

# License file
cp -f  $PACK_BUILD/edl-v10 $PACK_BUILD/edl-v10.txt 

# Remove some unnecessary files
rm -f  $PACK_BUILD/.cproject
rm -f  $PACK_BUILD/.gitignore
rm -f  $PACK_BUILD/.project
rm -f  $PACK_BUILD/.travis.yml
rm -f  $PACK_BUILD/travis-*
rm -f  $PACK_BUILD/library.properties
rm -rf $PACK_BUILD/.settings
rm -rf $PACK_BUILD/Debug

# Run Schema Check (for Linux only):
# sudo apt-get install libxml2-utils

if [ $(uname -s) = "Linux" ]
  then
  echo "Running schema check for ${PACK_VENDOR}.${PACK_NAME}.pdsc"
  xmllint --noout --schema "${CMSIS_TOOLSDIR}/../PACK.xsd" "${PACK_BUILD}/${PACK_VENDOR}.${PACK_NAME}.pdsc"
  errorlevel=$?
  if [ $errorlevel -ne 0 ]; then
    echo "build aborted: Schema check of $PACK_VENDOR.$PACK_NAME.pdsc against PACK.xsd failed"
    echo " "
    exit
  fi
else
  echo "Use MDK PackInstaller to run schema validation for $PACK_VENDOR.$PACK_NAME.pdsc"
fi

# Run Pack Check and generate PackName file with version
"${PACKCHK}" "${PACK_BUILD}/${PACK_VENDOR}.${PACK_NAME}.pdsc" \
  -i "${CMSIS_PACK_ROOT}/.Web/ARM.CMSIS.pdsc" \
  -i "${CMSIS_PACK_ROOT}/.Web/ARM.mbedTLS.pdsc" \
  -i "${CMSIS_PACK_ROOT}/.Web/MDK-Packs.IoT_Socket.pdsc" \
  -x M396 -x M382 \
  -n PackName.txt
errorlevel=$?
if [ $errorlevel -ne 0 ]; then
  echo "build aborted: pack check failed"
  echo " "
  exit
fi

PACKNAME=$(cat PackName.txt)
rm -rf PackName.txt

# Archiving
# $ZIP a $PACKNAME
echo "creating pack file $PACKNAME"
#if $PACK_WAREHOUSE directory does not exist create it
if [ ! -d "$PACK_WAREHOUSE" ]; then
  mkdir -p "$PACK_WAREHOUSE"
fi
pushd "$PACK_WAREHOUSE" > /dev/null
PACK_WAREHOUSE=$(pwd)
popd  > /dev/null
pushd "$PACK_BUILD" > /dev/null
PACK_BUILD=$(pwd)
"$ZIP" a "$PACK_WAREHOUSE/$PACKNAME" -tzip
popd  > /dev/null
errorlevel=$?
if [ $errorlevel -ne 0 ]; then
  echo "build aborted: archiving failed"
  exit
fi

echo "build of pack succeeded"
# Clean up
echo "cleaning up ..."

rm -rf "$PACK_BUILD"
echo " "

echo Completed CMSIS-Pack Generation: $(date)
