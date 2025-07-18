#!/bin/bash
#SBATCH --job-name=example_rnaseq_process       # Job name
#SBATCH --mail-type=END                         # Mail events (NONE, BEGIN, END, FAIL, ALL)
#SBATCH --mail-user=shve3678@colorado.edu           # Where to send mail
#SBATCH --nodes=1                               # Number of nodes requested
#SBATCH --ntasks=2                              # Number of CPUs (processor cores/tasks)
#SBATCH --mem=1gb                               # Memory limit
#SBATCH --time=00:30:00                        # Time limit hrs:min:sec
#SBATCH --partition=short                      # Partition/queue requested on server
#SBATCH --output=/scratch/Users/shve3678/homework-day4/%x_%j.out       # Standard output:  the %x will be replaced with job_name and the %j by the job id
#SBATCH --error=/scratch/Users/shve3678/homework-day4/%x_%j.err        # Standard error log

### Displays the job context
echo Job: $SLURM_JOB_NAME with ID $SLURM_JOB_ID
echo Running on host `hostname`
echo Job started at `date +"%T %a %d %b %Y"`
echo Directory is `pwd`
echo Using $SLURM_NTASKS processors across $SLURM_NNODES nodes

##############################
### Assigns path variables ###
##############################

## the fastq files will be used as input to fastqc and trimmomatic
## trimmed reads will then be passed on to the mapping step
FASTQ=/scratch/Shares/public/sread2025/homework_data_files/day4
DATADIR=/scratch/Users/shve3678/homework-day4   #day4 scratch working directory
FASTQC=${DATADIR}/fastqc
HISAT2=${DATADIR}/hisat2
TRIM=${DATADIR}/trimmomatic
BACKUP=/Users/shve3678/workshop-day4

FILENAME=chr21Ethan_repA    # Prefix of the files to analyze

mkdir -p $FASTQC $HISAT2 $TRIM

######################
### Loads modules   ##
######################
module load fastqc/0.11.5 
module load trimmomatic
module load hisat2/2.1.0
module load samtools/1.8

#######################
##Run the pipeline   ##
#######################
##1: Run fastqc on the samples (here run on example file ${FILENAME}.RNA.end1.fastq)

fastqc -o $FASTQC $FASTQ/$FILENAME.RNA.end1.fastq

##2: Trim FASTQ Files

java -jar /opt/trimmomatic/0.36/trimmomatic-0.36.jar PE \
 -threads 2 \
 -phred33 \
 -trimlog ${TRIM}/trimlog \
 ${FASTQ}/${FILENAME}.RNA.end1.fastq ${FASTQ}/${FILENAME}.RNA.end2.fastq \
 ${TRIM}/${FILENAME}.RNA.end1.trimmed.fastq ${TRIM}/${FILENAME}.RNA.end1.unpaired.fastq \
 ILLUMINACLIP:/opt/trimmomatic/0.36/adapters/TruSeq3-PE.fa:2:30:10 \
 LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:36

##3: Check Post-Trimming QC stats

fastqc -o ${FASTQC} ${TRIM}/*.trimmed.fastq

##4: Map trimmed reads to reference genome

##5: Convert SAM file to BAM file and index the BAM files
##The BAM file is a compressed binary version of a SAM file, so takes up less space
##The sorted bam also takes up less space
###5.1 - convert SAM to BAM

###5.2 - sort bam file

###5.3 - index sorted bam file

##6: Backup and clean up
###6.1 - remove your SAM and unsorted BAM file

###6.2 - back up your scripts and results


## An alternate way to do step 6 is to backup everything that you need and then delete your
## entire scratch working directory. As long as the inputs are still present, you can
## regenerate the outputs from the rest of the pipeline

echo Job finished at `date +"%T %a %d %b %Y"`
