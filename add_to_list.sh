DATA_PATH="/data/app"
ADDON_D_PATH="/system/addon.d/99-apps_in_system.sh"
ADDON_D_LIST="/system/addon.d/apps_in_system.list"
SAVED_PACKAGES_PATH="/system/addon.d/pack_in_system.list"
PRIV_APP="/system/priv-app/"
SYSTEM_APP="/system/app/"

echo "Add app's folder to addon.d script by alekseik1"
echo "Which folder would you like to check?"
echo "1 --\> /system/priv-app"
echo "2 --\> /system/app"
read k
if [[ $k -eq 1 ]]
then
  CURR_PATH=$PRIV_APP
else
  CURR_PATH=$SYSTEM_APP
fi

# Just in case it is ro-system
echo "Remounting /system as read-write..."
mount -o remount,rw /system
echo "Done!"

echo "Now choose the app you wish to add to addon.d script"
APPS=($(find $CURR_PATH -type d -maxdepth 1))
k=0
for i in ${APPS[@]}; do 
echo "$k --\> $i"
k=$((k+1))
done

echo "Choose an app (0-$((k-1))):"
read n
files=$(find ${APPS[$n]} -type f)

# Now, write files to addon.d
echo "
Listing files... And writing them to addon.d script...
"
for i in $files; do
echo $i
echo $i >> $ADDON_D_LIST
done

# Check Addon.d list for duplicates
echo "
Checking addon.d script for duplices..."
sort -u $ADDON_D_LIST  > $ADDON_D_LIST.tmp
cat $ADDON_D_LIST.tmp
mv $ADDON_D_LIST.tmp $ADDON_D_LIST
echo "Done!
"


echo '#!/sbin/sh
# 
# /system/addon.d/99-apps_in_system.sh
# During a CM upgrade, this script backs up Your apps moved to /system.
# /system is formatted and reinstalled, then the files are restored.
# Author: alekseik1
#
. /tmp/backuptool.functions
list_files() {
cat <<EOF' > $ADDON_D_PATH
for i in $(cat $ADDON_D_LIST); do
echo $(echo $i | sed "s/\/system\///g") >> $ADDON_D_PATH
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

# Get /system back
echo "Remounting /system as read-only..."
mount -o remount,ro /system
echo "Done!"
