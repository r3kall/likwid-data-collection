#!/bin/bash
source likwid-common.sh

#### GLOBALS #############################################################################
readonly DIR="data/raw"  # mkdir -p dirpath
readonly WORKLOAD_ARRAY=(copy)  # copy_mem daxpy daxpy_avx daxpy_mem_avx stream stream_avx stream_mem triad triad_mem_avx copy_sse daxpy_sse stream_sp_avx_fma ddot_sp update )
readonly FREQUENCY_ARRAY=(1000000 1200000)  # 1300000 1400000 1500000 1600000 1700000 1800000 1900000 2000000 2100000 2200000)
readonly NUM_THREAD=(1 4)


#######################################
# Run a single test.
# Globals:
#   LIKWID
#   DIR
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
  # local CS=$(( $2 - 1))  -C 0-$CS
  $LIKWID -T 100ms -o $DIR/$1-$2-$3-$4.csv  likwid-bench -t $1 -w S0:$4:$2 -s $5 > "$DIR/$1-$2-$3-$4.stdout" 2> /dev/null
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
  # disable_c_states
  # disabling turbo boost
  disableboost
  # setting governor
  # setgov userspace
  # number of workloads
  local len=${#WORKLOAD_ARRAY[@]}
  echo -e "$(MSG) Number of Workloads to profile: $len"

  local t_start
  for f in "${FREQUENCY_ARRAY[@]}"; do
    # setting cpu frequency
    setfreq $f
    for c in "${NUM_THREAD[@]}"; do
      for t in "${WORKLOAD_ARRAY[@]}"; do

        #echo -e "$(MSG) Test (1GB): $t frequency: $f GHz num_thread: $c"
        #t_start=`date +%s`
        #run_test $t $c $f 1GB 768
        #echo -e "$(MSG) Test Duration: $(($(date +%s)-$t_start)) seconds"
        
        #echo -e "$(MSG) Test (128MB): $t frequency: $f GHz num_thread: $c"
        #t_start=`date +%s`
        #run_test $t $c $f 128MB 6144
        #echo -e "$(MSG) Test Duration: $(($(date +%s)-$t_start)) seconds"
        
        echo -e "$(MSG) Test (1MB): $t frequency: $f GHz num_thread: $c"
        t_start=`date +%s`
        run_test $t $c $f 1MB 6
        echo -e "$(MSG) Test Duration: $(($(date +%s)-$t_start)) seconds"
        
        echo -e "$(MSG) Test (64kB): $t frequency: $f GHz num_thread: $c"
        t_start=`date +%s`
        run_test $t $c $f 64kB 6
        echo -e "$(MSG) Test Duration: $(($(date +%s)-$t_start)) seconds"

      done
    done
  done

  # enable c states
  # enable_c_states
  # re-setting governor and boost
  # setgov performance
  enableboost

  # end total time
  local end=`date +%s`
  echo -e "$(MSG) Total Duration: $((($end-$start)/60)) minutes"
}


# EXIT FUNCTION
function control_c {
  echo -en "\n#### Caught SIGINT; Clean up and Exit \n"
  # enable c states
  # enable_c_states
  # re-setting governor and boost
  # setgov performance
  enableboost
  exit $?
}


function main() {
  [[ $EUID -ne 0 ]] && echo "This script must be run as root." && exit 1
  [ ! -d $DIR ] && sudo -u $LIKWID_USER mkdir -p $DIR
  testing
  chown -R $LIKWID_USER:$LIKWID_USER $DIR
}

trap control_c SIGINT
trap control_c SIGTERM

main

#### END #################################################################################
