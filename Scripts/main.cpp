#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <random>
#include <chrono>
#include <unistd.h>

#include "Rcpp.h"
#include "Util.hpp"
#include "Egg.hpp"
#include "Parent.hpp"

// The number of iterations for each model or parameter set of a given model
int ITERATIONS;

// Energetic parameters for easy theoretical analysis in life history course report
constexpr static double BASE_ENERGY[1] 	         = {100};
constexpr static double INCUBATION_METABOLISM[1] = {10};
constexpr static double FORAGING_METABOLISM[1]   = {15};
constexpr static double MIN_ENERGY_THRESHOLD[1]  = {15};
constexpr static double MAX_ENERGY_THRESHOLD[1]  = {80};

std::vector<double> MAX_ENERGY_THRESHOLD;

// Multiplicative coefficients for mean of foraging dist
constexpr static double FORAGING_MEANS[10] = {10, 20, 30, 40, 50, 60, 70, 80, 90, 100};

// All output in from the model is written directly to file
constexpr static char OVERLAP_SWAP_FNAME[]  = "maxEnergy_output.txt";
// constexpr static char FORAGING_MEAN_FNAME[] = "foraging_mean_output.txt";

constexpr static char BOUTS_FNAME[] = "bouts.txt";

// Need a single, static random generator device to let us only seed once
static std::mt19937* randGen;

// Prototypes -- see functions for documentation
void breedingSeason_OVERLAP_SWAP(Parent&, Parent&, Egg&, int);
void breedingSeason_FORAGING_MEAN(Parent&, Parent&, Egg&, int);
void runModel(int, void(*)(Parent&, Parent&, Egg&, int), std::string);
void printBoutInfo(std::string, std::string, std::string, std::vector<int>, int);

// [[Rcpp::export]]
int main()
{

	ITERATIONS = 8000000;
	int base = 1;
	for (int i = 0; i < ITERATIONS/100000; i++) {
		MAX_ENERGY_THRESHOLD.push_back(base + i);
	}


	// Record model timing to help me know which computer is the fanciest
	auto startTime = std::chrono::system_clock::now();

	// Seed static random generator device with ridiculous C++11 things
	auto seed = std::chrono::high_resolution_clock::now().time_since_epoch().count();
	std::mt19937 r = std::mt19937(seed);
	randGen = &r;

	// All output to R terminals has to be with Rcout
	Rcpp::Rcout << "\n\n\n" << "Beginning model runs" << "\n\n\n";

	// Format header for all bouts record for OVERLAP_SWAP model
	std::ofstream outfile;
	std::string s(BOUTS_FNAME);
	outfile.open("Output/" + s, std::ofstream::trunc);
	outfile << "model,state,boutLength,iteration\n";
	outfile.close();

	/*
		Call each model by passing model info (including the *function itself),
		to the runModel function, which runs the model and writes output to 
		file. Models with parameter coefficient sets are multiplied by the number
		of coefficients, so all sets run for ITERATIONS iteration.
	*/  
	runModel(ITERATIONS, *breedingSeason_OVERLAP_SWAP, OVERLAP_SWAP_FNAME);
	// runModel(ITERATIONS*10, *breedingSeason_FORAGING_MEAN, FORAGING_MEAN_FNAME);

	// Report output and exit
	auto endTime = std::chrono::system_clock::now();
	std::chrono::duration<double> runTime = endTime - startTime;

	Rcpp::Rcout << "All model output written" << "\n"
				<< "Runtime in "
				<< runTime.count() << " s."
				<< "\n";
	return 0;
}

/*
	Master function to call each model and write formatted output
	@param iterations the number of breeding season replicates
		   modelFunc ptr to model function itself to call directly
		   outfileName file to write output
*/
void runModel(int iterations, 
	      void (*modelFunc)(Parent&, Parent&, Egg&, int iter), 
	      std::string outfileName) 
{
	// Start formatted output
	std::ofstream outfile;
	outfile.open("Output/" + outfileName, std::ofstream::trunc);

	// Header column for CSV format
	outfile << "iteration,hatchSuccess,hatchDays,neglect,maxNeglect,"
		<< "endEnergy_M,meanEnergy_M,varEnergy_M,"
		<< "endEnergy_F,meanEnergy_F,varEnergy_F,"
		<< "meanIncubation_M,varIncubation_M,numIncubation_M,"
		<< "meanForaging_M,varForaging_M,numForaging_M,"
		<< "meanIncubation_F,varIncubation_F,numIncubation_F,"
		<< "meanForaging_F,varForaging_F,numForaging_F,"
		<< "incubationMetabolism,foragingMetabolism,"
		<< "minEnergyThreshold,maxEnergyThreshold"
		<< "\n";

	// Initialize output objects once, overwrite each iteration
	std::vector<bool> hatchSuccess = std::vector<bool>();
	std::vector<double> hatchDays = std::vector<double>();
	std::vector<int> totNeglect = std::vector<int>();
	std::vector<int> maxNeglect = std::vector<int>();

	std::vector<double> energy_M = std::vector<double>();
	std::vector<double> energy_F = std::vector<double>();

	std::vector<int> incubationBouts_M = std::vector<int>();
	std::vector<int> foragingBouts_M = std::vector<int>();
	std::vector<int> incubationBouts_F = std::vector<int>();
	std::vector<int> foragingBouts_F = std::vector<int>();

	for (int i = 0; i < iterations; i++) {

		// Printing 1/10th progress updates
		if (iterations >= 10 && i % (iterations/10) == 0) {
			Rcpp::Rcout << "LHSP Model for " + outfileName + " on Iteration: " 
				    << i << "\n";
		}

		// Intialize new individuals for each season
		Parent pm = Parent(Sex::male, randGen);
		Parent pf = Parent(Sex::female, randGen);
		Egg egg = Egg();

		// Run the given breeding season model funciton
		modelFunc(pm, pf, egg, i);

		// Store individual bout output from simplest models
		bool printBouts = false;
		std::string model = "";

		// printBouts = true;
		// model = "foraging_mean";

		if (printBouts) {
			printBoutInfo(BOUTS_FNAME, model, "incubating", pm.getIncubationBouts(), i);
			printBoutInfo(BOUTS_FNAME, model, "incubating", pf.getIncubationBouts(), i);
			printBoutInfo(BOUTS_FNAME, model, "foraging",   pm.getForagingBouts(), i);
			printBoutInfo(BOUTS_FNAME, model, "foraging",   pf.getForagingBouts(), i);
		}

		// Save results of each season

		// successful season?
		// For life history course report, a season failed if either of the parents died 
		// (energy dropped below 0), or max neglect extended past 7 day streak
		bool didHatch = true;
		if (egg.getMaxNeg() >= 7 || !pm.isAlive() || !pf.isAlive()) {
			didHatch = false;
		}
		hatchSuccess.push_back(didHatch);		   		
		
		hatchDays.push_back(egg.getIncubationDays());  			// number of days to hatch

		totNeglect.push_back(egg.getTotNeg());		   		// total neglect
		maxNeglect.push_back(egg.getMaxNeg());		   		// max neglect streak

		energy_M = pm.getEnergyRecord();			   	// full season energy M
		energy_F = pf.getEnergyRecord();			  	// full season energy F

		incubationBouts_M = pm.getIncubationBouts();   			// inc. bout record M
		foragingBouts_M = pm.getForagingBouts();	   		// forgaging bout record M
		incubationBouts_F = pf.getIncubationBouts();   			// inc. bout record F
		foragingBouts_F = pf.getForagingBouts();	   		// foraging bout record F

		double endEnergy_M = energy_M[energy_M.size()-1];		// energy at end of season M
		double meanEnergy_M = vectorMean(energy_M);			// mean energy across season M
		double varEnergy_M = vectorVar(energy_M);			// variance in energy across season M

		double endEnergy_F = energy_F[energy_F.size()-1];		// energy at end of season F
		double meanEnergy_F = vectorMean(energy_F);			// mean energy across season F
		double varEnergy_F = vectorVar(energy_F);			// variance in energy across season F

		double meanIncubation_M = vectorMean(incubationBouts_M);	// mean inc. bout length M
		double varIncubation_M = vectorVar(incubationBouts_M);		// variance in inc. bout length M
		double numIncubation_M = incubationBouts_M.size();		// number of inc. bouts M

		double meanForaging_M = vectorMean(foragingBouts_M);		// mean foraging bout length M
		double varForaging_M = vectorVar(foragingBouts_M);		// variance in foraging bout length M
		double numForaging_M = foragingBouts_M.size();			// number of foraging bouts M

		double meanIncubation_F = vectorMean(incubationBouts_F);	// mean inc. bout length F
		double varIncubation_F = vectorVar(incubationBouts_F);		// variance in inc. bout length F
		double numIncubation_F = incubationBouts_F.size();		// number of inc. bouts F

		double meanForaging_F = vectorMean(foragingBouts_F);		// mean foraging bout lenght F
		double varForaging_F = vectorVar(foragingBouts_F);		// variance in foraging bout length F
		double numForaging_F = foragingBouts_F.size();			// number of foraging bouts F

		// same for both sexes for life history evolution course report
		double incubationMetabolism = pm.getIncubationMetabolism();
		double foragingMetabolism = pm.getForagingMetabolism();
		double minEnergyThreshold = pm.getMinEnergyThreshold();
		double maxEnergyThreshold = pm.getMaxEnergyThreshold();

		// Write output in CSV format
		outfile << i << ","
		        << hatchSuccess[i] << ","
			<< hatchDays[i] << ","
			<< totNeglect[i] << ","
			<< maxNeglect[i] << ","
			<< endEnergy_M << ","
			<< meanEnergy_M << ","
			<< varEnergy_M << ","
			<< endEnergy_F << ","
			<< meanEnergy_F << ","
			<< varEnergy_F << ","
			<< meanIncubation_M << ","
			<< varIncubation_M << ","
			<< numIncubation_M << ","
			<< meanForaging_M << ","
			<< varForaging_M << ","
			<< numForaging_M << ","
			<< meanIncubation_F << ","
			<< varIncubation_F << ","
			<< numIncubation_F << ","
			<< meanForaging_F << ","
			<< varForaging_F << ","
			<< numForaging_F << ","
			<< incubationMetabolism << ","
			<< foragingMetabolism << ","
			<< minEnergyThreshold << ","
			<< maxEnergyThreshold << "\n";
	}

	// Close file and exit
	outfile.close();
	Rcpp::Rcout << "Final output written to " << outfileName << "\n\n";
}

void breedingSeason_OVERLAP_SWAP(Parent& pm, Parent& pf, Egg& egg, int iter) {

	// Manually setting energetic parameters for life history evolution course test
	pm.setEnergy(BASE_ENERGY[0]);
	pm.setIncubationMetabolism(INCUBATION_METABOLISM[0]);
	pm.setForagingMetabolism(FORAGING_METABOLISM[0]);
	pm.setMinEnergyThreshold(MIN_ENERGY_THRESHOLD[0]);
	pm.setMaxEnergyThreshold(MAX_ENERGY_THRESHOLD[iter % MAX_ENERGY_THRESHOLD.size()]);

	pf.setEnergy(BASE_ENERGY[0]);
	pf.setIncubationMetabolism(INCUBATION_METABOLISM[0]);
	pf.setForagingMetabolism(FORAGING_METABOLISM[0]);
	pf.setMinEnergyThreshold(MIN_ENERGY_THRESHOLD[0]);
	pf.setMaxEnergyThreshold(MAX_ENERGY_THRESHOLD[iter % MAX_ENERGY_THRESHOLD.size()]);

	/* 
		Breeding season lasts a set amount, with no neglect effects
		(but keeping track of neglect)
	*/
	while (!egg.isHatched()) {		

		// Check if parent is incubating
		bool incubated = false;
		if (pm.getState() == State::incubating ||
		    pf.getState() == State::incubating) {
			
			incubated = true;
		}

		// Counting egg neglect
		egg.eggDay(incubated);

		// Parent behavior, including state change
		pm.parentDay();
		pf.parentDay();

		// If both parents are now incubating before the start of the 
		// next day, send the parent previously incubating away, while
		// the newly arrived parent stays to incubate afresh
		if (pm.getState() == State::incubating &&
		    pf.getState() == State::incubating) {
			
			State previousMaleState = pm.getPreviousDayState();
			State previousFemaleState = pf.getPreviousDayState();

			if (previousMaleState == State::incubating &&
			    previousFemaleState == State::foraging) {
				pm.changeState();
			} else if (previousFemaleState == State::incubating &&
			           previousMaleState == State::foraging) {
				pf.changeState();
			} 

			/*
				On the rare occasion where both individuals switch from
				foraging to incubating simultaenously in a timestep, 
				a random parent is sent to switch
			*/
			else {				
				if ((double)rand() / RAND_MAX <= 0.5) {
					pm.changeState();
				} else {
					pf.changeState();
				}
			}
		}
	}
}

void breedingSeason_FORAGING_MEAN(Parent& pm, Parent&pf, Egg& egg, int iter) {

	// Mod math access to global parameter arrays, again
	double newForagingMean = FORAGING_MEANS[iter % 10];

	// Both parents get a new foraging distribution mean for the season
	pm.setForagingDistribution(newForagingMean, Parent::FORAGING_SD);
	pf.setForagingDistribution(newForagingMean, Parent::FORAGING_SD);

	// Then begin all behavior from OVERLAP_SWAP
	breedingSeason_OVERLAP_SWAP(pm, pf, egg, iter);
}

void printBoutInfo(std::string fname, std::string model, std::string tag, std::vector<int> v, int iter) {
	std::ofstream of;
	of.open("Output/" + fname, std::ofstream::app);

	for (int i = 0; i < v.size(); i++) {
		of << model << "," << tag << "," << v[i] << "," << iter << "\n";
	}

	of.close();
}