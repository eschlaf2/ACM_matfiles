#!/bin/csh
#$ -pe omp 12
#$ -N output
#$ -m ea 
#$ -v HOMEDIR=/projectnb/cruzmartinlab/emily/
#$ -v datapath=/projectnb/cruzmartinlab/lab_data/WWY_080116_3/axons/Results/
#$ -v color=red
#$ -v outfile=/projectnb/cruzmartinlab/lab_data/WWY_060116_3_axons_11-29-16
#$ -v notes=''

echo "datapath: $datapath" >> ${HOMEDIR}NOTES.txt
echo "color: $color" >> ${HOMEDIR}NOTES.txt
echo "outfile: $outfile" >> ${HOMEDIR}NOTES.txt
echo -e "notes: $notes \n" >> ${HOMEDIR}NOTES.txt

# matlab -nodisplay -r "path = tif2P2mat('$datapath','$color'); segmentCa2P(path,[],[],'$outfile');exit"

matlab -nodisplay -r "segmentCa2Pcopy('$datapath',[],[],'$outfile');exit"

