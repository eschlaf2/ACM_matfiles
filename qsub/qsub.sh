#!/bin/csh
#$ -pe omp 12
#$ -N out.002-085_red
#$ -m ea 
#$ -v HOMEDIR=/projectnb/cruzmartinlab/emily/
#$ -v datapath=/projectnb/cruzmartinlab/lab_data/WWY_080116_3/002-085/
#$ -v color=red
#$ -v outfile=$datapath
#$ -v notes=''

echo "datapath: $datapath" >> ${HOMEDIR}NOTES.txt
echo "color: $color" >> ${HOMEDIR}NOTES.txt
echo "outfile: $outfile" >> ${HOMEDIR}NOTES.txt
echo -e "notes: $notes \n" >> ${HOMEDIR}NOTES.txt

# matlab -nodisplay -r "segmentCa2P; exit"
# matlab -nodisplay -r "segmentCopy; exit"

matlab -nodisplay -r "path = registerCaIm('$datapath','$color'); exit"

# matlab -nodisplay -r "segmentCa2P(path,[],[],'$outfile');exit"

# matlab -nodisplay -r "segmentCa2Pcopy('$datapath',[],[],'$outfile');exit"

