#!/bin/bash
source likwid-common.sh

#### GLOBALS #############################################################################
readonly DIR_AGGREGATED="data/raw-iter"  # mkdir -p dirpath
readonly WORKLOAD_ARRAY=(copy)  # triad_avx stream_mem)
readonly FREQUENCY_ARRAY=(0.8 1.5 2.0 2.5 3.0 3.2)
readonly NUM_THREAD=(1 2 4)
readonly ITER_ARRAY=(512 768 1024)

#######################################
# Run a single test.
# Globals:
#   LIKWID
#   LIKWID_USER
#   DIR_AGGREGATED
# Arguments:
#   $1: (str) test name [ref: likwid-bench -a]
#   $2: (int) number of cores
#   $3: (flt) frequency [expressed in GHz]
#   $4: (str) working size [kB, MB, GB]
#   $5: (int) number of iterations
# Returns:
#   None
#######################################
function run_test {
  local CS=$(( $2 - 1))
  local DIR="$DIR_AGGREGATED/iter-$5"
  [ ! -d $DIR ] && sudo -u $LIKWID_USER mkdir -p $DIR
  # $LIKWID -T 100ms -o $DIR/$1-$2-$3-$4.csv -C 0-$CS likwid-bench -t $1 -w S0:$4 -i $5 > "$DIR/$1-$2-$3-$4.stdout" 2> /dev/null
}


#######################################
# Main Testing function.
# Globals:
#   MSG
#   FREQUENCY_ARRAY
#   TEST_ARRAY
#   NUM_THREAD
# Arguments:
#   None
# Returns:
#   None
#######################################
function testing {
  # start total time
  local start=`date +%s`
  # disable c states
  disable_c_states
  # disabling turbo boost
  disableboost
  # setting governor
  setgov userspace
  # number of workloads
  local len=${#WORKLOAD_ARRAY[@]}
  echo -e "$(MSG) Number of Workloads to profile: $len"

  local t_start
  for f in "${FREQUENCY_ARRAY[@]}"; do
    # setting cpu frequency
    setfreq "${f}GHz"
    for c in "${NUM_THREAD[@]}"; do
      for t in "${WORKLOAD_ARRAY[@]}"; do
        for iter in "${ITER_ARRAY[@]}"; do
          echo -e "$(MSG) Test (1GB): $t frequency: $f GHz num_thread: $c"
          t_start=`date +%s`
          run_test $t $c $f 1GB $iter
          echo -e "$(MSG) Test Duration: $(($(date +%s)-$t_start)) seconds"
        done
      done
    done
  done

  # enable c states
  enable_c_states
  # re-setting governor and boost
  setgov performance
  enableboost

  # end total time
  local end=`date +%s`
  echo -e "$(MSG) Total Duration: $((($end-$start)/60)) minutes"
}


# EXIT FUNCTION
function control_c {
  echo -en "\n#### Caught SIGINT; Clean up and Exit \n"
  # enable c states
  enable_c_states
  # re-setting governor and boost
  setgov performance
  enableboost
  exit $?
}


function main() {
  [[ $EUID -ne 0 ]] && echo "This script must be run as root." && exit 1
  [ ! -d $DIR_AGGREGATED ] && sudo -u $LIKWID_USER mkdir -p $DIR_AGGREGATED
  testing
  chown -R $LIKWID_USER:$LIKWID_USER $DIR_AGGREGATED
}

trap control_c SIGINT
trap control_c SIGTERM

main

#### END #################################################################################
