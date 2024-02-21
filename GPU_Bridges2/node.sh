#!/bin/bash -l

set -x

#cd $WEST_SIM_ROOT
cd $1; shift
source env.sh
export WEST_JOBID=$1; shift
export SLURM_NODENAME=$1; shift
export CUDA_VISIBLE_DEVICES_ALLOCATED=$1; shift
# export LOCAL=/local/$WEST_JOBID
echo "starting WEST client processes on: "; hostname
echo "current directory is $PWD"
echo "environment is: "
env | sort

#May need to get the CUDA_VISIBLE_DEVICES env
local_cuda=`cat $SGE_JOB_SPOOL_DIR/environment |grep CUDA_VISIBLE_DEVICES`
export $local_cuda
echo "CUDA_VISIBLE_DEVICES = " $CUDA_VISIBLE_DEVICES

w_run "$@" &> west-$SLURM_NODENAME-node.log

echo "Shutting down.  Hopefully this was on purpose?"
