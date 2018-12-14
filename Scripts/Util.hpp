#pragma once

#include <vector>
#include <numeric>
#include <cmath>

// Returns mean of vector contents
double vectorMean(std::vector<double>&);
double vectorMean(std::vector<int>&);		// overloaded

// Returns variance of vector contents
double vectorVar(std::vector<double>&);
double vectorVar(std::vector<int>&);		// overloaded