#!/bin/bash
#-----------------------------------------------------------------------------------------------------------------------------------------------------------------
# Script Name: moodle-plugin-audit.sh
# Includes: moodle-paths.sh
# Required: Moosh - Moodle Shell for command-line Moodle administration.
# Ensure Moosh is installed and accessible in your PATH.
# More info at: https://moosh-online.com/
# Author: Charles Beadle
# Created: 2023-04-06
# Last Modified: 2023-04-06
# Description: This is a tool designed to automate the process of verifying the presence of a specific plugin on all instances and ensuring that the plugin
# is using the correct branch. The script provides an option to switch the plugin branch to the desired one and run a Moodle upgrade.
# Usage: sudo ./moodle-plugin-audit.sh
#-----------------------------------------------------------------------------------------------------------------------------------------------------------------

echo
read -p "Enter the Moodle version that these instances should be on. Just provide the release number. For example, 4.1.2: " MOODLE_VERSION
read -p "Starting from the moodle directory, provide the path to the plugin. For example, mod/attendance: " PLUGIN_PATH
read -p "What plugin branch are we checking for. For example, MOODLE_401_STABLE: " PLUGIN_BRANCH

echo -e "\nMoodle version: $MOODLE_VERSION"
echo -e "\nPlugin path: $PLUGIN_PATH"
echo -e "\nPlugin branch: $PLUGIN_BRANCH\n"

read -p "Are these values correct? " CONTINUE
if ! [[ "$CONTINUE" =~ ^[Yy]$  ]]
then
echo -e "\nExiting\n"
exit
fi

echo -e "\nCreating a list of instances. This will take a minute...\n"

declare -a moodle_difference
declare -a plugin_difference
declare -a missing_plugin

INSTANCES=$(./moodle-paths.sh)

echo -e "Checking to see if any of the instances are running a version other than $MOODLE_VERSION\n"

for INSTANCE in $INSTANCES
do
	cd "$INSTANCE"
	RELEASE=$(sudo -u www-data moosh config-get | grep -E "\[release\]" | grep -oE "[0-9]\.[0-9]\.[0-9]")
        if ! [[ "$RELEASE" == "$MOODLE_VERSION"  ]]
	then
		moodle_difference+=("$RELEASE $INSTANCE")
	fi
done

if [ "${#moodle_difference[@]}" -gt 0 ]
then
	echo -e "The following instances don't match the Moodle version we are checking for:\n"
	sleep 4
	for INSTANCE in "${moodle_difference[@]}"
	do
		echo "$INSTANCE"
	done
	echo -e "\nGiven that our instances aren't all running the same version, we'll exit here, as the script requires them all to be the same.\n"
	exit
fi

echo -e "Confirming that the plugin directory exists on each instance\n"

for INSTANCE in $INSTANCES
do
if ! [ -d "$INSTANCE/$PLUGIN_PATH" ]
then
	missing_plugin+=("$INSTANCE")
fi
done

if [ "${#missing_plugin[@]}" -gt 0 ]
then
	echo -e "The plugin is missing from the following instances:\n"
	for INSTANCE in "${missing_plugin[@]}"
	do
		echo "$INSTANCE"
	done
	echo -e "\nGiven that not all instances have the plugin installed, we'll exit here, as the script requires each instance to have the plugin installed.\n"
	exit
fi

echo -e "Checking if any of the plugins are on a branch other than $PLUGIN_BRANCH\n"

for INSTANCE in $INSTANCES
do
	cd "$INSTANCE/$PLUGIN_PATH"
	BRANCH=$(sudo -u www-data git symbolic-ref --short HEAD)
	if ! [[ "$BRANCH" == "$PLUGIN_BRANCH"  ]]
	then
		plugin_difference+=("$INSTANCE")
	fi
done

if [ "${#plugin_difference[@]}" -gt 0  ]
then
	echo -e "The plugin is on a branch other than $PLUGIN_BRANCH on the following instances:\n"
	for INSTANCE in "${plugin_difference[@]}"
	do
		echo "$INSTANCE"
	done
	echo
	read -p "Do you want to switch plugin branches to $PLUGIN_BRANCH on the instances listed above, and run a Moodle upgrade? " CHECKOUT
        if ! [[ "$CHECKOUT" =~ ^[Yy]$  ]]
	then
		echo -e "\nExiting\n"
	        exit
	fi

	echo -e "\nCorrecting plugin branches\n"

        for INSTANCE in "${plugin_difference[@]}"
        do
		cd "$INSTANCE/$PLUGIN_PATH"
		sudo -u www-data git checkout "$PLUGIN_BRANCH"
		cd "$INSTANCE"
		sudo -u www-data php admin/cli/upgrade.php --non-interactive
	done
	echo -e "The plugin branches have been corrected, and the instances have been upgraded.\n"
	exit
fi

echo "The Moodle versions all match $MOODLE_VERSION"
echo "The plugin exists on each instance"
echo "The plugin branch matches $PLUGIN_BRANCH on each instance"
echo -e "\nNothing to do. Exiting\n"

