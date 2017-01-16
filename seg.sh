#!/bin/csh
#$ -pe omp 12
#$ -V
#$ -N output.seg
#$ -m ea 

matlab -nodisplay -r "$run; exit"
