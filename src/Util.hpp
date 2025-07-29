#pragma once

#include <vector>
#include <numeric>
#include <cmath>
#include <fstream>

#include "Parent.hpp"
#include "Egg.hpp"

// Returns mean of vector contents
double vectorMean(std::vector<double>&);
double vectorMean(std::vector<int>&);		// overloaded

// Returns variance of vector contents
double vectorVar(std::vector<double>&);
double vectorVar(std::vector<int>&);		// overloaded

// Counts the number of strings matching a key in a vector
int isolateHatchResults(std::vector<std::string>, std::string);

// Converts a {min, max, by} vector to a list of parameters
std::vector<double> paramVector(const double[3]);
std::vector<int> paramVector(const int p[3]); // overloaded

// Prints bout info to a file
void printBoutInfo(std::string, std::string, std::string, std::vector<int>);

// Check season success based on different failure criteria
std::string checkSeasonSuccess(Parent&, Parent&, Egg&);

// Print a day's energetic and state information to the system
void printDailyInfo(Parent&, Parent&, Egg&);
