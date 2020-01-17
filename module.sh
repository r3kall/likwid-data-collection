#!/bin/bash

date () {
  command date +"\e[1m|$USER|%F|%T|\e[0m"
}

error () {
  command date +"\e[1m\e[31m|$USER|%F|%T|error|\e[0m"
}

function checkModule {
  # check if kernel module msr is loaded.
  if ! lsmod | grep "$1" &> /dev/null ; then
    modprobe "$1"
    echo -e "$(date) kernel module '$1' activated."
  fi
}


[[ $EUID -ne 0 ]] && echo "This script must be run as root." && exit 1

# Check and gives permissions to normal users for the 'msr' module.
checkModule 'msr'
chmod o+rw /dev/cpu/*/msr

# Check if the cpu scaling driver is 'acpi-cpufreq'.
if [ $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_driver) != "acpi-cpufreq" ]; then
  echo -e "$(error) 'acpi-cpufreq' scaling driver needed."
  exit 1
fi

# Check the module 'cpufreq_userspace' (to enable userspace scaling policy).
checkModule 'cpufreq_userspace'

