#!/bin/bash

# Version: 1.0 
# Date: 2018-05-25
# This bash script generates a CMSIS Software Pack:
#
# Requirements:
# bash shell
# curl
# zip (zip archiving utility) 
# 

# Upstream repository
UPSTREAM_URL=https://api.github.com/repos/eclipse/paho.mqtt.embedded-c
#UPSTREAM_TAG=v1.1.0
UPSTREAM_TAG=29ab2aa

# Pack Vendor
PACK_VENDOR=MDK-Packs
# Pack Name
PACK_NAME=Paho_MQTT

# NO NEED TO EDIT BELOW
# Contributions merge
CONTRIB_MERGE=./contributions/merge
# Contributions additional folders/files
CONTRIB_ADD=./contributions/add

# Pack Destination Folder
PACK_DESTINATION=./

# Pack Build Folder
PACK_BUILD=./build

# Pack build utilities Repository
UTILITIES_URL=https://github.com/ARM-software/CMSIS_5/blob/master/
UTILITIES_TAG=1.0.0
UTILITIES_DIR=./Utilities
UTILITIES_OS=Win32
if [ $UTILITIES_OS = "Win32" ]; then
  ZIP="/c/Program\ Files/7-Zip/7z.exe"
else
  ZIP=zip
fi


# if not present, fetch utilities
if [ ! -d $UTILITIES_DIR ]; then
  mkdir $UTILITIES_DIR
  pushd $UTILITIES_DIR
  mkdir $UTILITIES_OS
  # PackChk
  curl -L $UTILITIES_URL/CMSIS/Utilities/$UTILITIES_OS/PackChk.exe?raw=true -o $UTILITIES_OS/PackChk.exe
  # SVDConv
  curl -L $UTILITIES_URL/CMSIS/Utilities/$UTILITIES_OS/SVDConv.exe?raw=true -o $UTILITIES_OS/SVDConv.exe
  popd
fi

#if $PACK_BUILD folder does not exist create it and fetch content
if [ ! -d $PACK_BUILD ]; then
  mkdir $PACK_BUILD
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

# Run Pack Check and generate PackName file
$UTILITIES_DIR/$UTILITIES_OS/PackChk.exe $PACK_BUILD/$PACK_VENDOR.$PACK_NAME.pdsc -n PackName.txt
errorlevel=$?

if [ $errorlevel -ne 0 ]; then
  echo "build aborted: pack check failed"
  exit
fi

PACKNAME=`cat PackName.txt`
rm -rf PackName.txt

# Archiving
# $ZIP a $PACKNAME
pushd $PACK_BUILD
/c/Program\ Files/7-Zip/7z.exe a ../$PACKNAME -tzip
popd
errorlevel=$?
if [ $errorlevel -ne 0 ]; then
  echo "build aborted: archiving failed"
  exit
fi

echo "build of pack succeeded"
# Clean up
echo "cleaning up"
rm -rf $PACK_BUILD
rm -rf $UTILITIES_DIR
