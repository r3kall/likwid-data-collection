#!/bin/bash

#### GLOBALS #############################################################################
LIKWID_USER="rutigliano"
GROUP_ARRAY=($(likwid-perfctr -a | tail -n +3 | cut -b 1-15))
GROUP_FLAGS=$(printf -- "-g %s " "${GROUP_ARRAY[@]}")
LIKWID="likwid-perfctr $GROUP_FLAGS -M 0"


#### UTIL ################################################################################
function MSG { command date +"\e[1m|$USER|%F|%T|\e[0m"; }
function ERR { command date +"\e[1m\e[31m|$USER|%F|%T|error|\e[0m"; }


#### TURBO BOOST (deactivated during tests) ##############################################

#######################################
# Disable Turbo Boost.
# Globals:
#   MSG
# Arguments:
#   None
# Returns:
#   None
#######################################
function disableboost {
# Disable Turbo Boost.
  if [ -f "/sys/devices/system/cpu/cpufreq/boost" ]; then
    bash -c "echo 0 > /sys/devices/system/cpu/cpufreq/boost"
  fi
  echo -e "$(MSG) Boost Disabled."
}


#######################################
# Activate Turbo Boost.
# Globals:
#   MSG
# Arguments:
#   None
# Returns:
#   None
#######################################
function enableboost {
  if [ -f "/sys/devices/system/cpu/cpufreq/boost" ]; then
    bash -c "echo 1 > /sys/devices/system/cpu/cpufreq/boost"
  fi
  echo -e "$(MSG) Boost Enabled."
}


#### CPUPOWER ############################################################################

#######################################
# Set the governor. Refer to 'cpupower'.
# Globals:
#   MSG
# Arguments:
#   (string) governor [ex: performance, userspace]
# Returns:
#   None
#######################################
function setgov {
  cpupower --cpu all frequency-set -g $1 > /dev/null
  echo -e "$(MSG) CPU Governor set to $1."
}

#######################################
# Set the cpu frequency. Refer to 'cpupower'.
# Globals:
#   None
# Arguments:
#   (int) frequency [refer to 'cpupower frequency-info']
# Returns:
#   None
#######################################
function setfreq {
  # cpupower --cpu all frequency-set -f $1 > /dev/null
  bash -c "echo $1 > /sys/devices/system/cpu/cpu*/cpufreq/scaling_setspeed"
}


#######################################
# Enable all C states. Refer to 'cpupower'.
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
#######################################
function enable_c_states {
  cpupower idle-set -E > /dev/null
}


#######################################
# Disable all C states with latency greater than zero (all). Refer to 'cpupower'.
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
#######################################
function disable_c_states {
  cpupower idle-set -D 0 > /dev/null
}
