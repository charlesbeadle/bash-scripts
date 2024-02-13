#!/bin/bash
#--------------------------------------------------------------------------------------------
# Script Name: moodle-toggle-maint.sh
# Includes: moodle-paths.sh
# Author: Charles Beadle
# Created: 2023-08-04
# Last Modified: 2023-08-04
# Description: Enables or disables maintenance mode for all Moodle instances on the server
# Usage: sudo ./moodle-toggle-maint.sh {--enable|--disable}
#--------------------------------------------------------------------------------------------

case "$1" in
--enable)
  ACTION="Enabling"
  ;;
--disable)
  ACTION="Disabling"
  ;;
*)
  echo -e "Usage: sudo ./moodle-toggle-maint.sh {--enable|--disable}\n"
  exit 1
  ;;
esac

echo -e "$ACTION maintenance mode for all instances.\n"

INSTANCES=$(./moodle-paths.sh)

if [[ -z $INSTANCES ]]; then
  echo -e "Error: No Moodle instances found.\n"
  exit 1
fi

for INSTANCE in $INSTANCES; do
  sudo -u www-data php "${INSTANCE}/admin/cli/maintenance.php" "$1"
done
