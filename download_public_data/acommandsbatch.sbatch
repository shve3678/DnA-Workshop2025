#!/bin/bash                                                                                                                                                      

#SBATCH --job-name=get_data # Job name
#SBATCH --nodes=1                                                                                                                                                
#SBATCH --ntasks=1 # Num of CPU                                                                                                  
#SBATCH --time=24:00:00 # Time limit                                                                                                                
#SBATCH --partition short                                                                                                                                        
#SBATCH --mem=50mb # Memory                                                                                                                                 
#SBATCH --output=/scratch/Users/shve3678/workshopday10/eofiles/%x_%j.out
#SBATCH --error=/scratch/Users/shve3678/workshopday10/eofiles/%x_%j.err                                                              
#SBATCH --mail-type=FAIL                      
#SBATCH --mail-user=shve3678@colorado.edu 


################################################################################
####################### initialize directories  ################################
SRRPATH=$srrpath

##############################
##summary of run
##############################
printf "\nRun on: $(hostname)"
printf "\nRun from: $(pwd)"
printf "\nScript: $0\n"
date

printf "\nYou've requested $SLURM_CPUS_ON_NODE core(s).\n"

echo $outdir
echo $infile
echo $whichline

cd $outdir

# use wget to download the files
awk -v line="$whichline" 'NR == line {print $0}' "$infile" > "${outdir}shellscript${whichline}.sh"
cat ${outdir}header.txt ${outdir}shellscript${whichline}.sh > ${outdir}temp${whichline}.sh
mv temp${whichline}.sh ${outdir}shellscript${whichline}.sh
sh ${outdir}shellscript${whichline}.sh

echo "DONE!"
