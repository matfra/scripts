#!/bin/sh
PATCH_DIR=/root/updates
PATCH_TMP_DIR=/root/updates/tmp
PATCH_DONE_DIR=/root/updates/archives
LOGFILE=$PATCH_TMP_DIR/patch.log

if [ $# -eq 0 ]
  then
  echo "Please, give some Patch numbers as arguement :
  Example $0 CTX140052 CTX140015 CTX140089"
  exit 1
fi

LOCAL_UUID=`xe host-list |awk '/uuid/ {print $5}'`
echo "Patch will be applied on this machine : $LOCAL_UUID"
echo "You have 5 sec to hit CTRL + C"
sleep 5

for var in "$@"
do
  PATCH_URL=`curl --silent http://support.citrix.com/article/$var |awk -F "\"" '/<a href.*\.zip/ {print $2}' |uniq`
  PATCH_FILE=`basename $PATCH_URL`
  PATCH_NAME=${PATCH_FILE%.*}
  echo "Downloading patch at $PATCH_URL"
  mkdir $PATCH_DIR 2>/dev/null
  mkdir $PATCH_TMP_DIR 2>/dev/null
  mkdir $PATCH_DONE_DIR 2>/dev/null
  if test -f $PATCH_DONE_DIR/$PATCH_FILE ; then
    echo "Patch already downloaded, trying to apply it"
  else
    wget -P $PATCH_DONE_DIR $PATCH_URL
  fi
  unzip $PATCH_DONE_DIR/$PATCH_FILE -d $PATCH_TMP_DIR
  UUID=`xe patch-upload file-name=$PATCH_TMP_DIR/$PATCH_NAME.xsupdate`
  echo "Patch UUID : $UUID"
  echo "Installing the patch $PATCH_NAME"
  xe patch-apply host-uuid=$LOCAL_UUID uuid=$UUID
  rm -rf $PATCH_TMP_DIR
done
