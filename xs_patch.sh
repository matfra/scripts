#!/bin/sh
LOCAL_UUID="08112a18-4fc6-44b4-9e17-XXXXXXXXXXXX"
PATCH_DIR=/root/updates
PATCH_TMP_DIR=/root/updates/tmp
PATCH_DONE_DIR=/root/updates/archives

if [ $# -eq 0 ]
  then
  echo "Please, give some Patch numbers as arguement :
  Example $0 CTX140052 CTX140015 CTX140089"
  exit 1
fi


for var in "$@"
do
  PATCH_URL=`curl --silent http://support.citrix.com/article/$var |awk -F "\"" '/<a href.*\.zip/ {print $2}' |uniq`
  echo "Downloading patch at $PATCH_URL"
  mkdir $PATCH_DIR 2>/dev/null
  mkdir $PATCH_TMP_DIR 2>/dev/null
  mkdir $PATCH_DONE_DIR 2>/dev/null
  cd $PATCH_TMP_DIR
  wget $PATCH_URL
  PATCH_FILE=`basename $PATCH_URL`
  unzip $PATCH_FILE
  mv $PATCH_FILE $PATCH_DONE_DIR
  PATCH_NAME=${PATCH_FILE%.*}
  UUID=`xe patch-upload file-name=$PATCH_NAME.xsupdate 2>&1 |awk '/uuid/ {print $2}'`
  echo "Patch UUID : $UUID"
  echo "Installing the patch $PATCH"
  xe patch-apply host-uuid=$LOCAL_UUID uuid=$UUID
  rm -rf $PATCH_TMP_DIR
done
