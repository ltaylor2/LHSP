#!/bin/bash
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH -N 1
#SBATCH -n 1

make clean
make
./lhsp