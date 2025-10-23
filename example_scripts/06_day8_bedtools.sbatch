#!/bin/bash
#SBATCH --job-name=d8_bedtools                          # Job name
#SBATCH --mail-type=ALL                                 # Mail events (NONE, BEGIN, END, FAIL, ALL)
#SBATCH --mail-user=shve3678@colorado.edu	        # Where to send mail
#SBATCH --nodes=1                                       # Numbers of nodes
#SBATCH --ntasks=1                                      # Number of CPU (tasks)
#SBATCH --time=00:10:00                                 # Time limit hrs:min:sec
#SBATCH --mem=2gb                                       # Memory limit
#SBATCH -p short
#SBATCH --output=/scratch/Users/shve3678/day9/eofiles/%x_%j.out
#SBATCH --error=/scratch/Users/shve3678/day9/eofiles/%x_%j.err


################## USER INPUT ######################################

chrom_sizes='/scratch/Shares/public/genomes/hisatfiles/hg38/hg38.chrom.sizes'
ANNOT='/scratch/Shares/public/sread2025/cookingShow/day9b/annotation/hg38_refseq_cleaned.sorted.bed'
CHIP_DIR='/scratch/Shares/public/sread2025/cookingShow/day8b/whole_genome/macs/'
HCT116_DMSO_PEAKS=${CHIP_DIR}/HCT116_DMSO_peaks_clean.narrowPeak
HCT116_NUTLIN_PEAKS=${CHIP_DIR}/HCT116_NUTLIN_peaks_clean.narrowPeak
results='/scratch/Users/shve3678/day9/bedtools_results'
TSS_ANNOT=${results}/hg38_refseq_tssregion.bed

mkdir -p ${results}
################## JOB INFO ########################################

printf "\nRun on: $(hostname)"
printf "\nRun from: $(pwd)"
printf "\nScript: $0\n"
date

printf "\nYou've requested $SLURM_CPUS_ON_NODE core(s).\n"

################### LOAD MODULES ###################################

module load bedtools/2.28.0


################## SCRIPT ##########################################

# Write your bedtools/file manipulation commands here


# --- Which p53 peaks are associated with genes (not intergenic)
bedtools intersect -wo -a $HCT116_DMSO_PEAKS -b $ANNOT > $results/p53_assoc_genes.bed

# --- Which p53 peaks are entirely within genes
bedtools intersect -wo \
	-a $HCT116_DMSO_PEAKS \
	-b $ANNOT \
	-f 1.0 > $results/p53_assoc_genes_complete-overlap.bed

# --- Which p53 peaks are intergenic 
bedtools intersect -wo \
        -a $HCT116_DMSO_PEAKS \
        -b $ANNOT \
        -v > $results/p53_assoc_genes_intergenic.bed

# --- Which genes overlap with p53 peaks? 
bedtools intersect -wo -a $ANNOT -b $HCT116_DMSO_PEAKS > $results/genes_assoc_p53.bed

###---- Now do for Nutlin treated HCT116 Samples ----###
########################################################

# --- Which p53 peaks are associated with genes (not intergenic)
bedtools intersect -wo -a $HCT116_NUTLIN_PEAKS -b $ANNOT > $results/p53_assoc_genes.bed

# --- Which p53 peaks are entirely within genes
bedtools intersect -wo \
        -a $HCT116_NUTLIN_PEAKS \
        -b $ANNOT \
        -f 1.0 > $results/p53_assoc_genes_complete-overlap.bed

# --- Which p53 peaks are intergenic
bedtools intersect -wo \
        -a $HCT116_NUTLIN_PEAKS \
        -b $ANNOT \
        -v > $results/p53_assoc_genes_intergenic.bed

# --- Which genes overlap with p53 peaks?
bedtools intersect -wo -a $ANNOT -b $HCT116_NUTLIN_PEAKS > $results/genes_assoc_p53.bed

###########################################################
# --- Which genes have p53 ChIP sites in their promoters ##

## make promoter bedfile
# make TSS file
cat "$ANNOT" \
| awk '{FS=OFS="\t"}; {if ($6 == "+") print $1,$2,($2+1),$4,".",$6}' \
> "$results"/hg38_refseq_tss_pos.bed
cat "$ANNOT" \
| awk '{FS=OFS="\t"}; {if ($6 == "-") print $1,($3-1),$3,$4,".",$6}' \
> "$results"/hg38_refseq_tss_neg.bed
cat "$results"/hg38_refseq_tss_pos.bed \
"$results"/hg38_refseq_tss_neg.bed \
> $TSS_ANNOT

# output promoter bedfile
bedtools slop -i $TSS_ANNOT -g $TSS_ANNOT -l 1000 -r 100 > $results/promoters.bed


###---- Jacquard Calculations ----###

bedtools jaccard -a $HCT116_DMSO_PEAKS -b $ANNOT > $results/jaccard_index_c.txt
bedtools jaccard -a $HCT116_NUTLIN_PEAKS -b $ANNOT > $results/jaccard_index_n.txt
export JAC=$(awk '{print $1}' $results/jaccard_index_n.txt | wc -c)

bedtools shuffle -i $HCT116_NUTLIN_PEAKS -g $ANNOT > $results/shuffle_n.bed
SHUFFLED=$results/shuffle_n.bed

# sort
sort -k1,1 -k2,2n $SHUFFLED > $results/shuffle_n.sorted.bed
SORTED=$results/shuffle_n.sorted.bed

bedtools jaccard -a $SORTED -b $ANNOT > $results/jaccard_index_n_shuffled.txt

for i in $(awk '{print $1}' $SHUFFLED | wc)
do	
	bedtools shuffle -i $HCT116_NUTLIN_PEAKS -g $ANNOT > $results/shuffle_n_LOOP.bed
	SHUFFLED_NEW=$results/shuffle_n_LOOP.bed
	
	# sort
	sort -k1,1 -k2,2n $SHUFFLED_NEW > $results/shuffle_n_LOOP.sorted.bed
	SORTED_NEW=$results/shuffle_n_LOOP.sorted.bed
	
	bedtools jaccard -a $SORTED_NEW -b $ANNOT >> $results/jaccard_index_n_shuffled_LOOP.txt
	JAC_SHUFF=$results/jaccard_index_n_shuffled_LOOP.txt

	if [$(tail -n 1 $JAC_SHUFF | awk '{print $1}') > $(tail -n 1 $JAC | awk '{print $1}')]; then
		tail -n 1 $JAC_SHUFF | awk '{print $1}'
	else
		printf "\nAll good! \n"
	fi
done

printf "\nJob finished at " date "\n"
