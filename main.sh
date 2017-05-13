#!/bin/sh
# For debug purposes
#DATA_PATH="./data/app"
#ADDON_D_PATH="./system/addon.d/99-apps_in_system.sh"
#ADDON_D_LIST="./system/addon.d/apps_in_system.list"
DATA_PATH="/data/app"
ADDON_D_PATH="/system/addon.d/99-apps_in_system.sh"
ADDON_D_LIST="/system/addon.d/apps_in_system.list"
SAVED_PACKAGES_PATH="/system/addon.d/pack_in_system.list"

echo "Welcome to the script! Choose an app you want to move:"
# Getting apps list
APPS=($(find $DATA_PATH -type d -maxdepth 1))
k=0
for i in ${APPS[@]}; do 
echo "$k --\> $i"
k=$((k+1))
done

echo "Choose an app (0-$((k-1))):"
read n
#echo ${APPS[$n]} #--- App old directory
# All app files
files=$(find ${APPS[$n]} -type f)
#echo $files
# Copying directory to system path
dest=$(echo ${APPS[$n]} | sed "s/\/data\/app/\/system\/priv-app/g")
package=$(echo ${APPS[$n]} | sed "s/\/data\/app\///g")

echo
echo "Will now move from:"
echo ${APPS[$n]}
echo "to:"
echo $dest
echo "Let's check if app is already in /system"
if find $dest &>/dev/null
then
IS_ALREADY=1
echo "App is already in /system. It seems like you have updated it via Google Play. Would you like to integrate updates to /system?"
echo "[y/n]"
read INTEGRATE
else
IS_ALREADY=0
echo "App is not in /system. You seem to move it for the first time."

# Just in case it is ro-system
echo "Remounting /system as read-write..."
mount -o remount,rw /system
echo "Done!"

if [[ $IS_ALREADY -eq 0 ]]
then
  cp -af ${APPS[$n]} $dest && rm -rf ${APPS[$n]} && echo "Successfully moved!"
elif [[ $IS_ALREADY -eq 1 ]] && [[ $INTEGRATE -eq "y" ]]
then
  echo "This option is not supported yet"
  exit 0
else
  echo "Nothing to do, exiting..."
  exit 0
fi

# Now, write files to addon.d
for i in $files; do
echo $(echo $i | sed "s/\/data\/app/\/system\/priv-app/g") >> $ADDON_D_LIST
done

# Check Addon.d list for duplicates
cat $ADDON_D_LIST | uniq > $ADDON_D_LIST.tmp
mv $ADDON_D_LIST.tmp $ADDON_D_LIST


echo '#!/sbin/sh
# 
# /system/addon.d/99-apps_in_system.sh
# During a CM upgrade, this script backs up Your apps moved to /system.
# /system is formatted and reinstalled, then the files are restored.
# Author: alekseik1
#
. /tmp/backuptool.functions
list_files() {
cat <<EOF
' > $ADDON_D_PATH
for i in $(cat $ADDON_D_LIST); do
echo $i >> $ADDON_D_PATH
done

echo 'EOF
}
case "$1" in
  backup)
    echo "STARTING TO BACKUP YOUR SYSTEM APPS"
    list_files | while read FILE DUMMY; do
      echo backup_file $S/"$FILE"
      backup_file $S/"$FILE"
    done
    ls -al /tmp
    echo "ENDING TO BACKUP YOUR SYSTEM APPS"
  ;;
  restore)
    echo "STARTING TO RESTORE YOUR SYSTEM APPS"
    list_files | while read FILE REPLACEMENT; do
      R=""
      [ -n "$REPLACEMENT" ] && R="$S/$REPLACEMENT"
      [ -f "$C/$S/$FILE" ] && restore_file $S/"$FILE" "$R"
      echo $S/$FILE $( ls -alZ $S/$FILE )
    done
    echo "ENDING TO RESTORE YOUR SYSTEM APPS"
  ;;
  pre-backup)
    # Stub
  ;;
  post-backup)
    # Stub
  ;;
  pre-restore)
    # Stub
  ;;
  post-restore)
    # Stub
  ;;
esac' >> $ADDON_D_PATH
