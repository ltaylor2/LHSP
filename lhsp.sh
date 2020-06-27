#!/bin/bash
#SBATCH -p general
#SBATCH -c 10
#SBATCH --mem-per-cpu 6000
#SBATCH -t 20:00:00 
#SBATCH -J lhspSims 
#SBATCH -o lhsp_system.out
#SBATCH -e lhsp_error.out
#SBATCH --mail-type ALL

cd /home/lut2/project/LHSP/Scripts
make clean
make
./lhsp
