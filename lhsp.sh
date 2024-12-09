#!/bin/bash
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH -N 1
#SBATCH -n 1

/home/l.taylor/Documents/LHSP/src
make clean
make
./lhsp