#!/bin/csh
#$ -pe omp 12
#$ -N output
#$ -m ea 

matlab -nodisplay -r "figs4kramer; exit;"

