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
constexpr static int ITERATIONS = 100000;

constexpr static char OUTPUT_FNAME[] = "output.txt";

constexpr static double P_INCUBATING_METABOLISM[] = {0, 100, 10};
constexpr static double P_FORAGING_METABOLISM[] = {50, 250, 10};
constexpr static double P_MAX_ENERGY_THRESH[] = {500, 800, 10};
constexpr static double P_MIN_ENERGY_THRESH[] = {0, 800, 25};
constexpr static double P_FORAGING_MEAN[] = {100, 200, 10};
constexpr static double P_FORAGING_SD[] = {0, 100, 5};

// Need a single, static random generator device to let us only seed once
static std::mt19937* randGen;

// Prototypes -- see functions for documentation
void runModel(int, 
	      void(*)(Parent&, Parent&, Egg&), 
	      std::string,
	      std::vector<double>, 
	      std::vector<double>,
	      std::vector<double>,
	      std::vector<double>,
	      std::vector<double>,
	      std::vector<double>);

void breedingSeason(Parent&, Parent&, Egg&);
std::vector<double> paramVector(const double[3]);
std::string checkSeasonSuccess(Parent&, Parent&, Egg&);
void printBoutInfo(std::string, std::string, std::string, std::vector<int>);

// [[Rcpp::export]]
int main()
{
	// Record model timing to help me know which computer is the fanciest
	auto startTime = std::chrono::system_clock::now();

	// Seed static random generator device with ridiculous C++11 things
	auto seed = std::chrono::high_resolution_clock::now().time_since_epoch().count();
	std::mt19937 r = std::mt19937(seed);
	randGen = &r;

	// All output to R terminals has to be with Rcout
	Rcpp::Rcout << "\n\n\n" << "Beginning model runs" << "\n\n\n";

	std::vector<double> v_incubatingMetabolism = paramVector(P_INCUBATING_METABOLISM);
	std::vector<double> v_foragingMetabolism = paramVector(P_FORAGING_METABOLISM);
	std::vector<double> v_maxEnergyThresh = paramVector(P_MAX_ENERGY_THRESH);
	std::vector<double> v_minEnergyThresh = paramVector(P_MIN_ENERGY_THRESH);
	std::vector<double> v_foragingMean = paramVector(P_FORAGING_MEAN);
	std::vector<double> v_foragingSD = paramVector(P_FORAGING_SD);

	runModel(ITERATIONS, 
		 *breedingSeason, 
		 OUTPUT_FNAME,
		 v_incubatingMetabolism,
		 v_foragingMetabolism,
		 v_maxEnergyThresh,
		 v_minEnergyThresh,
		 v_foragingMean,
		 v_foragingSD);

	// Report output and exit
	auto endTime = std::chrono::system_clock::now();
	std::chrono::duration<double> runTime = endTime - startTime;

	Rcpp::Rcout << "All model output written" 
		    << "\n"
		    << "Runtime in "
		    << runTime.count() << " s."
	  	    << "\n";
	return 0;
}

/*
Master function to call each model and write formatted output
@param iterations the number of breeding season replicates
@param modelFunc ptr to model function itself to call directly
@param outfileName file to write output
*/
void runModel(int iterations, 
	      void (*modelFunc)(Parent&, Parent&, Egg&), 
	      std::string outfileName,
	      std::vector<double> v_incubatingMetabolism,
	      std::vector<double> v_foragingMetabolism,
	      std::vector<double> v_maxEnergyThresh,
	      std::vector<double> v_minEnergyThresh,
	      std::vector<double> v_foragingMean,
	      std::vector<double> v_foragingSD) 
{
	// Start formatted output
	std::ofstream outfile;
	outfile.open("Output/" + outfileName, std::ofstream::trunc);

	// Header column for CSV format
	outfile << "iteration,hatchSuccess,hatchDays,neglect,maxNeglect,"
		<< "endEnergy_M,meanEnergy_M,varEnergy_M,"
		<< "endEnergy_F,meanEnergy_F,varEnergy_F,"
		<< "baseEnergy,"
		<< "incubatingMetabolism,"
		<< "foragingMetabolism,"
		<< "maxEnergyThresh,"
		<< "minEnergyThresh,"
		<< "foragingMean,"
		<< "foragingSD"
		<< "\n";

	// Initialize output objects once, overwrite each iteration
	std::string hatchSuccess = "";
	double hatchDays = -1;
	int totNeglect = -1;
	int maxNeglect = -1;

	std::vector<double> energy_M = std::vector<double>();
	std::vector<double> energy_F = std::vector<double>();

	std::vector<int> incubationBouts_M = std::vector<int>();
	std::vector<int> foragingBouts_M = std::vector<int>();
	std::vector<int> incubationBouts_F = std::vector<int>();
	std::vector<int> foragingBouts_F = std::vector<int>();

	int totParamIterations = v_incubatingMetabolism.size() * v_foragingMetabolism.size() *
			  	 v_maxEnergyThresh.size() * v_minEnergyThresh.size() *
			  	 v_foragingMean.size() * v_foragingSD.size() * iterations;
	int paramIteration = 1;

	for (int a = 0; a < v_incubatingMetabolism.size(); a++) {
		double incubatingMetabolism = v_incubatingMetabolism[a];

	  for (int b = 0; b < v_foragingMetabolism.size(); b++) {
		  double foragingMetabolism = v_foragingMetabolism[b];
	 
	    for (int c = 0; c < v_maxEnergyThresh.size(); c++) {
	  	  double maxEnergyThresh = v_maxEnergyThresh[c];

	      for (int d = 0; d < v_minEnergyThresh.size(); d++) {
	      	  double minEnergyThresh = v_minEnergyThresh[d];

	        for (int e = 0; e < v_foragingMean.size(); e++) {
	          double foragingMean = v_foragingMean[e];

	          for (int f = 0; f < v_foragingSD.size(); f++) {
	            double foragingSD = v_foragingSD[f];
		    Rcpp::Rcout << "LHSP Model for searching parameter space of size " 
		                << totParamIterations
		                << " on combination #" << paramIteration
		                << " with " << iterations << " iterations per combination.\n";

	            for (int i = 0; i < iterations; i++) {

			Parent pm = Parent(Sex::male, randGen);
			Parent pf = Parent(Sex::female, randGen);
			Egg egg = Egg();

			pm.setIncubatingMetabolism(incubatingMetabolism);
			pf.setIncubatingMetabolism(incubatingMetabolism);

			pm.setForagingMetabolism(foragingMetabolism);
			pf.setForagingMetabolism(foragingMetabolism);

			pm.setMaxEnergyThresh(maxEnergyThresh);
			pf.setMaxEnergyThresh(maxEnergyThresh);

			pm.setMinEnergyThresh(minEnergyThresh);
			pf.setMinEnergyThresh(minEnergyThresh);

			pm.setForagingDistribution(foragingMean, foragingSD);
			pf.setForagingDistribution(foragingMean, foragingSD);

			// Run the given breeding season model funciton
			modelFunc(pm, pf, egg);

			hatchSuccess = checkSeasonSuccess(pm, pf, egg);
			hatchDays = egg.getIncubationDays();
			totNeglect = egg.getTotNeg();
			maxNeglect = egg.getMaxNeg();

			energy_M = pm.getEnergyRecord();			// full season energy M
			energy_F = pf.getEnergyRecord();			// full season energy F

			double endEnergy_M = energy_M[energy_M.size()-1];	// energy at end of season M
			double meanEnergy_M = vectorMean(energy_M);		// mean energy across season M
			double varEnergy_M = vectorVar(energy_M);		// variance in energy across season M

			double endEnergy_F = energy_F[energy_F.size()-1];	// energy at end of season F
			double meanEnergy_F = vectorMean(energy_F);		// mean energy across season F
			double varEnergy_F = vectorVar(energy_F);		// variance in energy across season F


			// Write output in CSV format
			outfile << i << ","
			        << hatchSuccess << ","
				<< hatchDays << ","
				<< totNeglect << ","
				<< maxNeglect << ","
				<< endEnergy_M << ","
				<< meanEnergy_M << ","
				<< varEnergy_M << ","
				<< endEnergy_F << ","
				<< meanEnergy_F << ","
				<< varEnergy_F << ","
				<< "\n";
	            }

	            paramIteration++;
	          }
	        }
	      }
	    }
	  }
	}

	// Close file and exit
	outfile.close();
	Rcpp::Rcout << "Final output written to " << outfileName << "\n\n";
}

std::string checkSeasonSuccess(Parent& pm, Parent& pf, Egg& egg) {
	if (egg.isHatched() && egg.isAlive() && pm.isAlive() && pf.isAlive()) {
		return "success";
	} else if ((!egg.isHatched() || !egg.isAlive()) && (!pm.isAlive() || !pf.isAlive())) {
		return "allFail";
	} else if (!pm.isAlive() || !pf.isAlive()) {
		return "parentFail";
	} else if (!egg.isHatched() && egg.isAlive()) {
		return "eggTimeFail";
	} else if (!egg.isAlive()) {
		return "eggColdFail";
	}

	return "unknownFail";
}

std::vector<double> paramVector(const double p[3]) {
	double min = p[0];
	double max = p[1];
	double by = p[2];

	std::vector<double> ret;
	for (double i = min; i <= max; i+=by) {
		ret.push_back(i);
	}
	return ret;
}

void breedingSeason(Parent& pm, Parent& pf, Egg& egg) {
	/* 
		Breeding season lasts until the egg hatches succesfully, or 
	 	if the egg hits the hard cut-off of incubation days due to 
	 	accumulated neglect 
	*/
	pf.setEnergy(pf.getEnergy() - egg.getEggCost());

	while (!egg.isHatched() && 
		(egg.getIncubationDays() <= egg.getMaxHatchDays())) {		

		// Check if parent is incubating
		bool incubated = false;
		if (pm.getState() == State::incubating ||
			pf.getState() == State::incubating) {
			
			incubated = true;
		}

		// Egg behavior based on incubation
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

void printBoutInfo(std::string fname, std::string model, std::string tag, std::vector<int> v) {
	std::ofstream of;
	of.open("Output/" + fname, std::ofstream::app);

	for (int i = 0; i < v.size(); i++) {
		of << model << "," << tag << "," << v[i] << "\n";
	}

	of.close();
}