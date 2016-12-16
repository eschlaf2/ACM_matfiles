#!/bin/csh
#$ -pe omp 12
#$ -N output
#$ -m ea 
#$ -v HOMEDIR=/projectnb/cruzmartinlab/emily/
#$ -v datapath=/projectnb/cruzmartinlab/lab_data/XL011-10_0914_Day15_Area0/
#$ -v color=green
#$ -v outfile=$datapath
#$ -v notes=''

echo "datapath: $datapath" >> ${HOMEDIR}NOTES.txt
echo "color: $color" >> ${HOMEDIR}NOTES.txt
echo "outfile: $outfile" >> ${HOMEDIR}NOTES.txt
echo -e "notes: $notes \n" >> ${HOMEDIR}NOTES.txt

matlab -nodisplay -r "path = tif2P2mat('$datapath','$color'); exit"

# segmentCa2P(path,[],[],'$outfile');exit"

# matlab -nodisplay -r "segmentCa2Pcopy('$datapath',[],[],'$outfile');exit"

