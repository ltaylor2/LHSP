#!/bin/bash
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH -N 1
#SBATCH -n 15
#SBATCH --mem 200G

cd /mnt/research/l.taylor/l.taylor/LHSP/src
make clean
make
./lhsp

cd /mnt/research/l.taylor/l.taylor/LHSP
Rscript --slave R/process_simulation_results.r
Rscript --slave R/analysis.r
