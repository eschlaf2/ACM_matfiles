#!/bin/bash
run="foldername='$1';$2"
export run
qsub ./seg.sh 
