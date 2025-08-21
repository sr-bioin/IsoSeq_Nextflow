#!/bin/bash -l
#SBATCH -J sqanti3
#SBATCH -o myjob.%A_%a.output   
#SBATCH -e myjob.%A_%a.error 
#SBATCH -p high
#SBATCH -t 99:99:99
#SBATCH -N 1  ##Numbers of nodes to run the job
#SBATCH -n 12 ##Number of processes for the job 
#SBATCH --mem 20000
##SBATCH --array=1,2

#Providing
#sample1=
#sample2=
#sample3=

#sample=sample$SLURM_ARRAY_TASK_ID
#echo ${!sample}


module load conda3
conda activate SQANTI3.env

export PATH=$PATH:/home/user/software/SQUANTI/SQANTI3-4.2
export PATH=$PATH:/home/user/software/SQUANTI/SQANTI3-4.2/cDNA_Cupcake/sequence
export PATH=$PATH:/home/user/software/SQUANTI/SQANTI3-4.2/utilities
export PATH=$PATH:/home/user/software/SQUANTI2/gffread	
export PATH=$PATH:/home/user/software/R/R-4.1.1/bin

	

	echo start on `date`

# Sqanti quality control
	
	sqanti3_qc.py ${!sample}.flnc_clustered.hq_minimap2.sorted.collapsed.gtf reference.gtf reference_genomic.fna -o ${!sample} --report pdf
	

##Filtering Isoforms using SQANTI3 and visualization
	
	sqanti3_RulesFilter.py /SQANTI3/${!sample}.flnc_clustered.hq_STAR.sorted.collapsed.rep_classification.txt ${!sample}.flnc_clustered.hq_STAR.sorted.collapsed.rep.renamed.fasta ${!sample}.flnc_clustered.hq_STAR.sorted.collapsed.rep_corrected.gtf -c 3


	echo end on `date`


	conda deactivate
