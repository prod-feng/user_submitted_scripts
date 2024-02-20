#!/bin/bash
#$ -N PROJECTNAME
#$ -j y
#$ -q gpu_long_2080ti
#$ -l ngpus=1
#$ -P kenprj

set -x
cd $SGE_O_WORKDIR
source env.sh || exit 1

env | sort

cd $WEST_SIM_ROOT
SERVER_INFO=$WEST_SIM_ROOT/west_zmq_info-$JOB_ID.json

# start server
$WEST_ROOT/bin/w_run --work-manager=zmq --n-workers=0 --zmq-mode=master --zmq-write-host-info=$SERVER_INFO --zmq-comm-mode=tcp &> west-$JOB_ID.log &

# wait on host info file up to one minute
for ((n=0; n<60; n++)); do
    if [ -e $SERVER_INFO ] ; then
        echo "== server info file $SERVER_INFO =="
        cat $SERVER_INFO
        break
    fi
    sleep 1
done

# exit if host info file doesn't appear in one minute
if ! [ -e $SERVER_INFO ] ; then
    echo 'server failed to start'
    exit 1
fi

# start clients, with the proper number of cores on each

cat $pe_hostfile  |awk '{print $1 ," ",$2}' >& SGE_NODELIST.log

# Read in nodename and #gpu
typeset -A nodelist
while IFS=$':= \t' read key value; do
  nodelist[$key]=$value
done <SGE_NODELIST.log

for node in "${!nodelist[@]}"; do
    ssh -o StrictHostKeyChecking=no $node $PWD/node.sh $SGE_O_WORKDIR $JOB_ID $node $CUDA_VISIBLE_DEVICES --work-manager=zmq --n-workers=${nodelist[$node]} --zmq-mode=client --zmq-read-host-info=$SERVER_INFO --zmq-comm-mode=tcp & 
    #MODIFY --n-workers to the same number of gpus you have!
done


wait

