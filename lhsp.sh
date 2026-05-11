#!/bin/bash
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH -N 1
#SBATCH -n 15

cd /home/l.taylor/Documents/LHSP/src
make clean
make
./lhsp

cd ..
Rscript --slave R/process_simulation_results.r
Rscript --slave R/analysis.r