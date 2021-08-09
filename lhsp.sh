#!/bin/bash
#SBATCH -p general 
#SBATCH -c 4
#SBATCH --mem-per-cpu 5000
#SBATCH -t 12:00:00
#SBATCH -J lhspSims
#SBATCH -o sysOut_lhsp.txt
#SBATCH -e errOut_lhsp.txt
#SBATCH --mail-type ALL

cd /home/lut2/project/LHSP/Scripts
make clean
make
./lhsp

cd /home/lut2/project/LHSP
module load miniconda
conda activate lhsp

Rscript Scripts/lhsp_visualizations.r
