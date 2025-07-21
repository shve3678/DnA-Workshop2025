#!/bin/bash

################################################################################                                                                                                                        
####################### initialize directories  ################################
################################################################################                                                                                                                        
 
indir=/scratch/Users/shve3678/workshopday10
wholefileoflines=${indir}/ena-file-download-selected-files-20250718-1710.sh
outdir=/scratch/Users/shve3678/workshopday10/fastqs/

mkdir -p $outdir

echo "Getting the SRR Accession Numbers"


nlines=`cat $wholefileoflines | wc -l`

echo $nlines

for i in $(seq 1 $nlines); 
do echo $i; 
   sbatch --export=outdir=$outdir,infile=$wholefileoflines,whichline=$i acommandsbatch.sbatch
done


echo "DONE!"
