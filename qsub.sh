#!/bin/csh
#$ -pe omp 8
#$ -m ea 
#$ -v HOMEDIR=/projectnb/cruzmartinlab/emily/
#$ -v datapath=/projectnb/cruzmartinlab/lab_data/WWY_080116_3/cell-bodies-1Hz/
#$ -v color=red
#$ -v outfile=/projectnb/cruzmartinlab/lab_data/WWY_060116_3_cellbodies_1Hz
#$ -v notes=''

echo "datapath: $datapath" >> ${HOMEDIR}NOTES.txt
echo "color: $color" >> ${HOMEDIR}NOTES.txt
echo "outfile: $outfile" >> ${HOMEDIR}NOTES.txt
echo -e "notes: $notes \n" >> ${HOMEDIR}NOTES.txt

matlab -nodisplay -r "tif2P2mat('$datapath','$color'); exit"
