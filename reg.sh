#!/bin/csh
#$ -pe omp 12
#$ -N out.reg
#$ -m ea 
#$ -V

matlab -nodisplay -r "path = registerCaIm('$datapath','$color'); exit"

