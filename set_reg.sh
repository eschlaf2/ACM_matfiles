#!/bin/bash
datapath=$1
color=$2
export datapath
export color
qsub ./reg.sh

