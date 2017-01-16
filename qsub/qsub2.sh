#!/bin/csh
#$ -pe omp 12
#$ -N axons
#$ -m ea 
#$ -v HOMEDIR=/projectnb/cruzmartinlab/emily/
#$ -v datapath=/projectnb/cruzmartinlab/lab_data/WWY_080116_3/cell-bodies-2Hz/
#$ -v color=red
#$ -v outfile=$datapath
#$ -v notes=''

echo "datapath: $datapath" >> ${HOMEDIR}NOTES.txt
echo "color: $color" >> ${HOMEDIR}NOTES.txt
echo "outfile: $outfile" >> ${HOMEDIR}NOTES.txt
echo -e "notes: $notes \n" >> ${HOMEDIR}NOTES.txt

matlab -nodisplay -r "cb.5Hz; cb2Hz; exit";
