#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <random>
#include <chrono>
#include <unistd.h>

#include "Util.hpp"
#include "Egg.hpp"
#include "Parent.hpp"

// The number of iterations for each model or parameter set of a given model
constexpr static int ITERATIONS = 10000;

constexpr static char OUTPUT_FNAME_STANDARD[] = "sims_standard.txt";
constexpr static char OUTPUT_FNAME_OVERLAPRAND[] = "sims_overlapRand.txt";
constexpr static char OUTPUT_FNAME_NOOVERLAP[] = "sims_noOverlap.txt";

constexpr static char OUTPUT_FNAME_COMPENSATE[] = "sims_compensate.txt";
constexpr static char OUTPUT_FNAME_COMPENSATE2[] = "sims_compensate2.txt";

constexpr static char OUTPUT_FNAME_RETALIATE[] = "sims_retaliate.txt";
constexpr static char OUTPUT_FNAME_RETALIATE2[] = "sims_retaliate2.txt";

constexpr static double P_MAX_ENERGY_THRESH[] = {0, 1000, 50};
constexpr static double P_MIN_ENERGY_THRESH[] = {0, 1000, 50};
constexpr static double P_FORAGING_MEAN[] = {130, 160, 3};

// Need a single, static random generator device to let us only seed once
static std::mt19937* randGen;

// Prototypes -- see functions for documentation
void runModel(int, 
	      void(*)(Parent&, Parent&, Egg&), 
	      std::string,
	      std::vector<double>,
	      std::vector<double>,
	      std::vector<double>);

void breedingSeason(Parent&, Parent&, Egg&);
void breedingSeason_overlapRand(Parent&, Parent&, Egg&);
void breedingSeason_noOverlap(Parent&, Parent&, Egg&);

void breedingSeason_compensate(Parent&, Parent&, Egg&);
void breedingSeason_compensate2(Parent&, Parent&, Egg&);

void breedingSeason_retaliate(Parent&, Parent&, Egg&);
void breedingSeason_retaliate2(Parent&, Parent&, Egg&);

std::vector<double> paramVector(const double[3]);
int isolateHatchResults(std::vector<std::string>, std::string);
void printBoutInfo(std::string, std::string, std::string, std::vector<int>);
std::string checkSeasonSuccess(Parent&, Parent&, Egg&);
void printDailyInfo(Parent&, Parent&, Egg&);

int main()
{
	// Record model timing to help me know which computer is the fanciest
	auto startTime = std::chrono::system_clock::now();

	// Seed static random generator device with ridiculous C++11 things
	auto seed = std::chrono::high_resolution_clock::now().time_since_epoch().count();
	std::mt19937 r = std::mt19937(seed);
	randGen = &r;

	// All output to R terminals has to be with Rcout
	std::cout << "\n\n\n" << "Beginning model runs" << "\n\n\n";

	std::vector<double> v_maxEnergyThresh = paramVector(P_MAX_ENERGY_THRESH);
	std::vector<double> v_minEnergyThresh = paramVector(P_MIN_ENERGY_THRESH);
	std::vector<double> v_foragingMean = paramVector(P_FORAGING_MEAN);

	std::cout << "Beginning STANDARD model run" << "\n";
	runModel(ITERATIONS, 
			 *breedingSeason, 
			 OUTPUT_FNAME_STANDARD,
			 v_maxEnergyThresh,
			 v_minEnergyThresh,
			 v_foragingMean);

	std::cout << "\n" << "Done with STANDARD model run\n";
	std::cout << "Beginning OVERLAP_RAND model run" << "\n\n";

	runModel(ITERATIONS, 
			 *breedingSeason_overlapRand, 
			 OUTPUT_FNAME_OVERLAPRAND,
			 v_maxEnergyThresh,
			 v_minEnergyThresh,
			 v_foragingMean);

	std::cout << "\n" << "Done with OVERLAP_RAND model run\n";
	std::cout << "Beginning NO_OVERLAP model run" << "\n\n";

	runModel(ITERATIONS, 
			 *breedingSeason_noOverlap,
			 OUTPUT_FNAME_NOOVERLAP,
			 v_maxEnergyThresh,
			 v_minEnergyThresh,
			 v_foragingMean);

	std::cout << "\n" << "Done with NO_OVERLAP model run\n";
	std::cout << "Beginning COMPENSATION model run" << "\n\n";

	runModel(ITERATIONS, 
			 *breedingSeason_compensate, 
			 OUTPUT_FNAME_COMPENSATE,
			 v_maxEnergyThresh,
			 v_minEnergyThresh,
			 v_foragingMean);

	std::cout << "\n" << "Done with COMPENSATION model run\n";
	std::cout << "Beginning COMPENSATION*2 model run" << "\n\n";

	runModel(ITERATIONS, 
			 *breedingSeason_compensate2, 
			 OUTPUT_FNAME_COMPENSATE2,
			 v_maxEnergyThresh,
			 v_minEnergyThresh,
			 v_foragingMean);


	std::cout << "\n" << "Done with COMPENSATION*2 model run\n";
	std::cout << "Beginning RETALIATION model run" << "\n\n";

	runModel(ITERATIONS, 
			 *breedingSeason_retaliate, 
			 OUTPUT_FNAME_RETALIATE,
			 v_maxEnergyThresh,
			 v_minEnergyThresh,
			 v_foragingMean);

	std::cout << "\n" << "Done with RETALIATION model run\n";
	std::cout << "Beginning RETALIATION*2 model run" << "\n\n";

	runModel(ITERATIONS, 
			 *breedingSeason_retaliate2, 
			 OUTPUT_FNAME_RETALIATE2,
			 v_maxEnergyThresh,
			 v_minEnergyThresh,
			 v_foragingMean);

	// Report output and exit
	auto endTime = std::chrono::system_clock::now();
	std::chrono::duration<double> runTime = endTime - startTime;

	std::cout << "All model output written" 
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
	      std::vector<double> v_maxEnergyThresh,
	      std::vector<double> v_minEnergyThresh,
	      std::vector<double> v_foragingMean)
{
	// Start formatted output
	std::ofstream outfile;
	outfile.open("../Output/" + outfileName, std::ofstream::trunc);

	// Header column for CSV format
	outfile << "iterations" << ","
		<< "maxEnergyThresh" << ","
		<< "minEnergyThresh" << ","
		<< "foragingMean" << ","
	    	<< "numSuccess" << ","
	    	<< "numAllFail" << ","
       		<< "numParentFail" << ","
		<< "numEggTimeFail" << ","
		<< "numEggColdFail" << ","
		<< "hatchDays" << ","
		<< "totNeglect" << ","
		<< "maxNeglect" << ","
		<< "endEnergy_F" << ","
		<< "meanEnergy_F" << ","
		<< "varEnergy_F" << ","
		<< "endEnergy_M" << ","
		<< "meanEnergy_M" << ","
		<< "varEnergy_M" << ","
		<< "meanIncBout_F" << ","
		<< "varIncBout_F" << ","
		<< "meanForagingBout_F" << ","
		<< "varForagingBout_F" << ","
		<< "meanIncBout_M" << ","
		<< "varIncBout_M" << ","
		<< "meanForagingBout_M" << ","
		<< "varForagingBout_M" << "\n";

	// Initialize output objects to store records from each parameter combo iteration
	// At the end of each param combination, summarize rates or mean values
	//  and only output one line for each combo

	std::vector<std::string> hatchResults = std::vector<std::string>();

	std::vector<double> hatchDays = std::vector<double>();
	std::vector<int> totNeglect = std::vector<int>();
	std::vector<int> maxNeglect = std::vector<int>();

	std::vector<double> energy_F = std::vector<double>();
	std::vector<double> endEnergy_F = std::vector<double>();
	std::vector<double> meanEnergy_F = std::vector<double>();
	std::vector<double> varEnergy_F = std::vector<double>();

	std::vector<double> energy_M = std::vector<double>();
	std::vector<double> endEnergy_M = std::vector<double>();
	std::vector<double> meanEnergy_M = std::vector<double>();
	std::vector<double> varEnergy_M = std::vector<double>();

	std::vector<double> meanIncubationBouts_F = std::vector<double>();
	std::vector<double> varIncubationBouts_F = std::vector<double>();

	std::vector<double> meanForagingBouts_F = std::vector<double>();
	std::vector<double> varForagingBouts_F = std::vector<double>();

	std::vector<double> meanIncubationBouts_M = std::vector<double>();
	std::vector<double> varIncubationBouts_M = std::vector<double>();

	std::vector<double> meanForagingBouts_M = std::vector<double>();
	std::vector<double> varForagingBouts_M = std::vector<double>();

	int totParamIterations = v_maxEnergyThresh.size() * 
				 v_minEnergyThresh.size() * 
				 v_foragingMean.size();
	int paramIteration = 1;

	for (unsigned int a = 0; a < v_maxEnergyThresh.size(); a++) {
		double maxEnergyThresh = v_maxEnergyThresh[a];

	for (unsigned int b = 0; b < v_minEnergyThresh.size(); b++) {
	    double minEnergyThresh = v_minEnergyThresh[b];

	for (unsigned int c = 0; c < v_foragingMean.size(); c++) {
		double foragingMean = v_foragingMean[c];

	    paramIteration++;	// Param combo complete, onto the next one!

	    if (minEnergyThresh >= maxEnergyThresh) {
	      	continue;
	    }
	        
		if (paramIteration % (totParamIterations/100) == 0) {
			std::cout << "Searching parameter space of size " 
		             << totParamIterations
		             << " on combo " << paramIteration
		             << " (" << iterations << " iters per combo)\n";
		}

        for (int i = 0; i < iterations; i++) {

        	Egg egg = Egg();

		Parent pf = Parent(Sex::female, randGen);
		Parent pm = Parent(Sex::male, randGen);

		pf.setMaxEnergyThresh(maxEnergyThresh);
		pf.setMinEnergyThresh(minEnergyThresh);
		pf.setForagingDistribution(foragingMean, pf.getForagingSD());

		pm.setMaxEnergyThresh(maxEnergyThresh);
		pm.setMinEnergyThresh(minEnergyThresh);
		pm.setForagingDistribution(foragingMean, pm.getForagingSD());

		// Run the given breeding season model funciton
		modelFunc(pf, pm, egg);

		hatchResults.push_back(checkSeasonSuccess(pf, pm, egg));
		hatchDays.push_back(egg.getIncubationDays());
		totNeglect.push_back(egg.getTotNeg());
		maxNeglect.push_back(egg.getMaxNeg());

		energy_F = pf.getEnergyRecord();						// full season energy F
		endEnergy_F.push_back(energy_F[energy_F.size()-1]);		// energy at end of season F
		meanEnergy_F.push_back(vectorMean(energy_F));			// mean energy across season F
		varEnergy_F.push_back(vectorVar(energy_F));				// variance in energy across season F

		energy_M = pm.getEnergyRecord();						// full season energy M
		endEnergy_M.push_back(energy_M[energy_M.size()-1]);		// energy at end of season M
		meanEnergy_M.push_back(vectorMean(energy_M));			// mean energy across season M
		varEnergy_M.push_back(vectorVar(energy_M));				// variance in energy across season M

		// accumulate the overall bout record for the entire season
		// across iterations for a param combo
		// Appends to the full param combo storage vector
		std::vector<int> currIncubationBouts_F = pf.getIncubationBouts();
		std::vector<int> currForagingBouts_F = pf.getForagingBouts();

		std::vector<int> currIncubationBouts_M = pm.getIncubationBouts();
		std::vector<int> currForagingBouts_M = pm.getForagingBouts();

		meanIncubationBouts_F.push_back(vectorMean(currIncubationBouts_F));
		varIncubationBouts_F.push_back(vectorVar(currIncubationBouts_F));

		meanForagingBouts_F.push_back(vectorMean(currForagingBouts_F));
		varForagingBouts_F.push_back(vectorVar(currForagingBouts_F));

		meanIncubationBouts_M.push_back(vectorMean(currIncubationBouts_M));
		varIncubationBouts_M.push_back(vectorVar(currIncubationBouts_M));

		meanForagingBouts_M.push_back(vectorMean(currForagingBouts_M));
		varForagingBouts_M.push_back(vectorVar(currForagingBouts_M));
        }

        // Calculate summary values from full param combo run
        int numSuccess = isolateHatchResults(hatchResults, "success");
        int numAllFail = isolateHatchResults(hatchResults, "allFail");
        int numParentFail = isolateHatchResults(hatchResults, "parentFail");
        int numEggTimeFail = isolateHatchResults(hatchResults, "eggTimeFail");
        int numEggColdFail = isolateHatchResults(hatchResults, "eggColdFail");

        double meanHatchDays = vectorMean(hatchDays);
        double meanTotNeglect = vectorMean(totNeglect);
        double meanMaxNeglect = vectorMean(maxNeglect);

        double meanEndEnergy_F = vectorMean(endEnergy_F);
        double meanMeanEnergy_F= vectorMean(meanEnergy_F);
        double meanVarEnergy_F = vectorMean(varEnergy_F);

        double meanEndEnergy_M = vectorMean(endEnergy_M);
        double meanMeanEnergy_M = vectorMean(meanEnergy_M);
        double meanVarEnergy_M = vectorMean(varEnergy_M);

        double meanMeanIncBout_F = vectorMean(meanIncubationBouts_F);
        double meanVarIncBout_F = vectorMean(varIncubationBouts_F);

        double meanMeanForagingBout_F = vectorMean(meanForagingBouts_F);
        double meanVarForagingBout_F = vectorMean(varForagingBouts_F);

        double meanMeanIncBout_M = vectorMean(meanIncubationBouts_M);
        double meanVarIncBout_M = vectorMean(varIncubationBouts_M);

        double meanMeanForagingBout_M = vectorMean(meanForagingBouts_M);
        double meanVarForagingBout_M = vectorMean(varForagingBouts_M);

        // Write output in CSV format
	outfile << iterations << ","
		<< maxEnergyThresh << ","
		<< minEnergyThresh << ","
		<< foragingMean << ","
	    	<< numSuccess << ","
	    	<< numAllFail << ","
      		<< numParentFail << ","
		<< numEggTimeFail << ","
		<< numEggColdFail << ","
		<< meanHatchDays << ","
		<< meanTotNeglect << ","
		<< meanMaxNeglect << ","
		<< meanEndEnergy_F << ","
		<< meanMeanEnergy_F << ","
		<< meanVarEnergy_F << ","
		<< meanEndEnergy_M << ","
		<< meanMeanEnergy_M << ","
		<< meanVarEnergy_M << ","
		<< meanMeanIncBout_F << ","
		<< meanVarIncBout_F << ","
		<< meanMeanForagingBout_F << ","
		<< meanVarForagingBout_F << ","
		<< meanMeanIncBout_M << ","
		<< meanVarIncBout_M << ","
		<< meanMeanForagingBout_M << ","
		<< meanVarForagingBout_M << "\n";		

	// Clear output vectors for next param combo
	hatchResults.clear();
        hatchDays.clear();
        totNeglect.clear();
        maxNeglect.clear();
        
      	energy_F.clear();
      	endEnergy_F.clear();
      	meanEnergy_F.clear();
      	varEnergy_F.clear();

        energy_M.clear();
        endEnergy_M.clear();
      	meanEnergy_M.clear();
      	varEnergy_M.clear();

      	meanIncubationBouts_F.clear();
      	varIncubationBouts_F.clear();

      	meanForagingBouts_F.clear();
      	varForagingBouts_F.clear();

      	meanIncubationBouts_M.clear();
      	varIncubationBouts_M.clear();

      	meanForagingBouts_M.clear();
      	varForagingBouts_M.clear();
	}
	}
	}

	// Close file and exit
	outfile.close();
	std::cout << "Final output written to " << outfileName << "\n";
}

void breedingSeason(Parent& pf, Parent& pm, Egg& egg) 
{
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
		if (pf.getState() == State::incubating ||
			pm.getState() == State::incubating) {
			
			incubated = true;
		}

		// Egg behavior based on incubation
		egg.eggDay(incubated);

		// Parent behavior, including state change
		pf.parentDay();
		pm.parentDay();

		// If both parents are now incubating before the start of the 
		// next day, send the parent previously incubating away, while
		// the newly arrived parent stays to incubate afresh
		if (pf.getState() == State::incubating &&
		    pm.getState() == State::incubating) {
			
			State previousFemaleState = pf.getPreviousDayState();
			State previousMaleState = pm.getPreviousDayState();

			if (previousFemaleState == State::incubating &&
			    previousMaleState == State::foraging) {
				pf.changeState();
				pf.setDidOverlap(true);

			} else if (previousMaleState == State::incubating &&
				   previousFemaleState == State::foraging) {
				pm.changeState();
				pm.setDidOverlap(true);
			}
			/*
			On the rare occasion where both individuals switch from
			foraging to incubating simultaenously in a timestep, 
			a random parent is sent to switch
			*/
			else {				
				if ((double)rand() / RAND_MAX <= 0.5) {
					pf.changeState();
					pf.setDidOverlap(true);
				} else {
					pm.changeState();
					pm.setDidOverlap(true);
				}
			}
		}
	}
}

void breedingSeason_overlapRand(Parent& pf, Parent& pm, Egg& egg) 
{
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
		if (pf.getState() == State::incubating ||
			pm.getState() == State::incubating) {
			
			incubated = true;
		}

		// Egg behavior based on incubation
		egg.eggDay(incubated);

		// Parent behavior, including state change
		pf.parentDay();
		pm.parentDay();

		// If both parents are now incubating before the start of the 
		// next day, pick a random parent to send back
		if (pf.getState() == State::incubating &&
		    pm.getState() == State::incubating) {
			if ((double)rand() / RAND_MAX <= 0.5) {
				pm.changeState();
			} else {
				pf.changeState();
			}
		}
	}
}

void breedingSeason_noOverlap(Parent& pf, Parent& pm, Egg& egg) 
{
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
		if (pf.getState() == State::incubating ||
		    pm.getState() == State::incubating) {
			
			incubated = true;
		}

		// Egg behavior based on incubation
		egg.eggDay(incubated);

		// Parent behavior, including state change
		pf.parentDay();
		pm.parentDay();
	}
}

void breedingSeason_compensate(Parent& pf, Parent& pm, Egg& egg) 
{
	/* 
		Breeding season lasts until the egg hatches succesfully, or 
	 	if the egg hits the hard cut-off of incubation days due to 
	 	accumulated neglect 
	*/
	pf.setShouldCompensate(true);
	pm.setShouldCompensate(true);

	breedingSeason(pf, pm, egg);
}

void breedingSeason_compensate2(Parent& pf, Parent& pm, Egg& egg) {
	pf.setReactDelay(2);
	pm.setReactDelay(2);

	breedingSeason_compensate(pf, pm, egg);
}

void breedingSeason_retaliate(Parent& pf, Parent& pm, Egg& egg) 
{
	/* 
		Breeding season lasts until the egg hatches succesfully, or 
	 	if the egg hits the hard cut-off of incubation days due to 
	 	accumulated neglect 
	*/
	pf.setShouldRetaliate(true);
	pm.setShouldRetaliate(true);

	breedingSeason(pf, pm, egg);
}

void breedingSeason_retaliate2(Parent& pf, Parent& pm, Egg& egg) {
	pf.setReactDelay(2);
	pm.setReactDelay(2);

	breedingSeason_retaliate(pf, pm, egg);
}

int isolateHatchResults(std::vector<std::string> results, std::string key)
{
	int ret = 0;
	for (unsigned int i = 0; i < results.size(); i++) {
		if (results[i].compare(key) == 0) {
			ret++;
		}
	}
	return ret;
}

std::vector<double> paramVector(const double p[3]) 
{
	double min = p[0];
	double max = p[1];
	double by = p[2];

	std::vector<double> ret;
	for (double i = min; i <= max; i+=by) {
		ret.push_back(i);
	}

	return ret;
}

void printBoutInfo(std::string fname, std::string model, std::string tag, std::vector<int> v) 
{
	std::ofstream of;
	of.open("Output/" + fname, std::ofstream::app);

	for (unsigned int i = 0; i < v.size(); i++) {
		of << model << "," << tag << "," << v[i] << "\n";
	}

	of.close();
}

std::string checkSeasonSuccess(Parent& pf, Parent& pm, Egg& egg) 
{
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

void printDailyInfo(Parent& pf, Parent& pm, Egg& egg) {
	int days = egg.getIncubationDays();
	double maxDays = egg.getMaxHatchDays();
	int eggNeglect = egg.getTotNeg();

	double femaleEnergy = pf.getEnergy();
	std::string femaleState = pf.getStrState();

	double maleEnergy = pm.getEnergy();
	std::string maleState = pm.getStrState();

	std::cout << "On day " << days << " of " << maxDays
	   	  << " with egg neglect " << eggNeglect << ".///"
	   	  << " Female is " << femaleState
	   	  << " with " << femaleEnergy << " energy.///"
	   	  << " Male is " << maleState
	   	  << " with " << maleEnergy << " energy.///\n";
}
