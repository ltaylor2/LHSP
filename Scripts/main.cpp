#include <iostream>
#include <thread>
#include <fstream>
#include <string>
#include <vector>
#include <random>
#include <chrono>
#include <unistd.h>

#include "Util.hpp"
#include "Egg.hpp"
#include "Parent.hpp"

// TODO Make key global constants cmd line input parameters

constexpr static int ITERATIONS = 10;

// Unique (will overwrite) output file for each model run,
constexpr static char OUTPUT_DIR[] = "/home/liam/Documents/LHSP/Output/";
constexpr static char OUTPUT_FNAME_UNI[] = "sims_uni.txt";
constexpr static char OUTPUT_FNAME_SEMI[] = "sims_semi.txt";
constexpr static char OUTPUT_FNAME_BI[] = "sims_bi.txt";

constexpr static double P_MAX_ENERGY_THRESH[] = {0, 1000, 50};
constexpr static double P_MIN_ENERGY_THRESH[] = {0, 1000, 50};
constexpr static double P_FORAGING_MEAN[] = {130, 330, 10};

// Need a single, static random generator device to let us only seed once
static std::mt19937* randGen;

// Function prototypes
void runModel(int iterations,
	            void (*modelFunc)(Parent&, Parent&, Egg&),
	            std::string outfileName,
	            std::vector<double> v_maxEnergyThresh,
	            std::vector<double> v_minEnergyThresh,
	            std::vector<double> v_foragingMean);

void breedingSeason_uni(Parent& pf, Parent& pm, Egg& egg);
void breedingSeason_semi(Parent& pf, Parent& pm, Egg& egg);
void breedingSeason_bi(Parent& pf, Parent& pm, Egg& egg);

int main()
{
	// Record model timing to help me know which computer is the fanciest
	auto startTime = std::chrono::system_clock::now();

	// Seed static random generator device with ridiculous C++11 things
	auto seed = std::chrono::high_resolution_clock::now().time_since_epoch().count();
	std::mt19937 r = std::mt19937(seed);
	randGen = &r;

	std::cout << "\n\n\nBeginning model runs\n\n\n";

	// Generate a vector of parameter values from {min, max, by} arrays
	std::vector<double> v_maxEnergyThresh = paramVector(P_MAX_ENERGY_THRESH);
	std::vector<double> v_minEnergyThresh = paramVector(P_MIN_ENERGY_THRESH);
	std::vector<double> v_foragingMean    = paramVector(P_FORAGING_MEAN);

	// Uniparental breeding season
	std::thread uni_thread(runModel,
		 					           ITERATIONS,
		 					           *breedingSeason_uni,
		 					           OUTPUT_FNAME_UNI,
					    	         v_maxEnergyThresh,
		 					           v_minEnergyThresh,
					    	         v_foragingMean);
	std::cout << "Initiated UNI Model Thread\n";

  std::thread semi_thread(runModel,
		 					            ITERATIONS,
		 					            *breedingSeason_semi,
		 					            OUTPUT_FNAME_SEMI,
					    	          v_maxEnergyThresh,
		 					            v_minEnergyThresh,
					    	          v_foragingMean);
	std::cout << "Initiated SEMI Model Thread\n";

  std::thread bi_thread(runModel,
		 					          ITERATIONS,
		 					          *breedingSeason_bi,
		 					          OUTPUT_FNAME_BI,
					    	        v_maxEnergyThresh,
		 					          v_minEnergyThresh,
					    	        v_foragingMean);
	std::cout << "Initiated BI Model Thread\n";

	uni_thread.join();
	std::cout << "Ended UNI Model Thread\n";

  semi_thread.join();
	std::cout << "Ended SEMI Model Thread\n";

  bi_thread.join();
	std::cout << "Ended BI Model Thread\n";

	// Report output and exit
	auto endTime = std::chrono::system_clock::now();
	std::chrono::duration<double> runTime = endTime - startTime;

	// Congrats you survived! I hope the storm-petrels did too.
	std::cout << "All model output written"
		  	    << std::endl
		        << "Runtime in "
		        << runTime.count() << " s."
	  	      << std::endl;
	return 0;
}

void runModel(int iterations,
	            void (*modelFunc)(Parent&, Parent&, Egg&),
	            std::string outfileName,
	            std::vector<double> v_maxEnergyThresh,
	            std::vector<double> v_minEnergyThresh,
	            std::vector<double> v_foragingMean)
{
	// Start formatted output
	std::ofstream outfile;
	outfile.open(OUTPUT_DIR + outfileName, std::ofstream::trunc);

	// Header column for CSV format
	outfile << "iterations" << ","
			    << "maxEnergyThresh_F" << ","
			    << "minEnergyThresh_F" << ","
			    << "maxEnergyThresh_M" << ","
			    << "minEnergyThresh_M" << ","
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
			    << "varForagingBout_M" << std::endl;

	/*
	Initialize output objects to store records from each parameter combo iteration
	At the end of each param combination, summarize rates or mean values
	and only output one line for each combo.
	NOTE one cannot keep a vector in active memory that doesn't have
		 summary values because you'll run out of memory, but you
		 can print output for each iteration to a file if you have the
		 drive space.
	*/

	// Factorized summary of final parent/egg state
	std::vector<std::string> hatchResults = std::vector<std::string>();

	// Egg results to track
	std::vector<double> hatchDays    = std::vector<double>();
	std::vector<int> totNeglect      = std::vector<int>();
	std::vector<int> maxNeglect      = std::vector<int>();

	// Female energy parameters to track
	std::vector<double> energy_F     = std::vector<double>();
	std::vector<double> endEnergy_F  = std::vector<double>();
	std::vector<double> meanEnergy_F = std::vector<double>();
	std::vector<double> varEnergy_F  = std::vector<double>();

	// Male energy parameters to track
	std::vector<double> energy_M     = std::vector<double>();
	std::vector<double> endEnergy_M  = std::vector<double>();
	std::vector<double> meanEnergy_M = std::vector<double>();
	std::vector<double> varEnergy_M  = std::vector<double>();

	// Female bouts-length information to track
	std::vector<double> meanIncubationBouts_F = std::vector<double>();
	std::vector<double> varIncubationBouts_F  = std::vector<double>();
	std::vector<double> meanForagingBouts_F   = std::vector<double>();
	std::vector<double> varForagingBouts_F    = std::vector<double>();

	// Male bout-length information to track
	std::vector<double> meanIncubationBouts_M = std::vector<double>();
	std::vector<double> varIncubationBouts_M  = std::vector<double>();
	std::vector<double> meanForagingBouts_M   = std::vector<double>();
	std::vector<double> varForagingBouts_M    = std::vector<double>();

	/*
	Total parameter space being searched
	NOTE I throw out any combinations where
	minEnergy [hunger] > maxEnergy [satiation],
	So this space is reduced to that array
	*/
	int totParamIterations = v_maxEnergyThresh.size() *
				 			             v_minEnergyThresh.size() *
				 			             v_maxEnergyThresh.size() *
 				 			             v_minEnergyThresh.size() *
				 			             v_foragingMean.size();

	int currParamIteration = 0;
	// For every maxEnergy value
	for (unsigned int a = 0; a < v_maxEnergyThresh.size(); a++) {
		double maxEnergyThresh_F = v_maxEnergyThresh[a];

	// (then) for every minEnergy value
	for (unsigned int b = 0; b < v_minEnergyThresh.size(); b++) {
	    double minEnergyThresh_F = v_minEnergyThresh[b];

	for (unsigned int c = 0; c < v_maxEnergyThresh.size(); c++) {
		double maxEnergyThresh_M = v_maxEnergyThresh[c];

	for (unsigned int d = 0; d < v_minEnergyThresh.size(); d++) {
		double minEnergyThresh_M = v_minEnergyThresh[d];

	// (then, then) for every foraging mean value
	for (unsigned int e = 0; e < v_foragingMean.size(); e++) {
		double foragingMean = v_foragingMean[e];

		// Mildly helpful progress update
		currParamIteration++;
		if (currParamIteration % (totParamIterations/10) == 0) {
			std::cout << "Approximate progress of "
					      << outfileName
					      << ": "
					      << round((double)currParamIteration / totParamIterations*100) << "%" << std::endl;
		}

	  // Skip if hunger threshold >= satiation threshold(doesn't make sense!)
	  if (minEnergyThresh_F >= maxEnergyThresh_F | minEnergyThresh_M >= maxEnergyThresh_M) {
	    	continue;
	  }

		// Replicate every parameter combination by i iterations
    for (int i = 0; i < iterations; i++) {

      // A fresh eggs
      Egg egg = Egg();

      // Two shiny new parents, one male and one female
		  Parent pf = Parent(Sex::female, randGen);
		  Parent pm = Parent(Sex::male, randGen);

		  // Set both parent's parameters according to the new combo
		  pf.setMaxEnergyThresh(maxEnergyThresh_F);
		  pf.setMinEnergyThresh(minEnergyThresh_F);
		  pf.setForagingDistribution(foragingMean, pf.getForagingSD());
		  pm.setMaxEnergyThresh(maxEnergyThresh_M);
		  pm.setMinEnergyThresh(minEnergyThresh_M);
		  pm.setForagingDistribution(foragingMean, pm.getForagingSD());

		  // Run the given breeding season model function,
		  modelFunc(pf, pm, egg);

			// Add this iteration's results to the parameter combination's trackers
			hatchResults.push_back(checkSeasonSuccess(pf, pm, egg));	// Factorized season result
			hatchDays.push_back(egg.getIncubationDays());			        // Total number of days (maybe limit)
			totNeglect.push_back(egg.getTotNeg());						        // Total neglect across season
			maxNeglect.push_back(egg.getMaxNeg());					          // Maximum neglect streak

			energy_F = pf.getEnergyRecord();							            // Full energy record (female)
			endEnergy_F.push_back(energy_F[energy_F.size()-1]);			  // Final energy value (female)
			meanEnergy_F.push_back(vectorMean(energy_F));				      // Arithmetic mean energy across season (female)
			varEnergy_F.push_back(vectorVar(energy_F));					      // Variance in energy across season (female)

			energy_M = pm.getEnergyRecord();							            // Full energy record (male)

      // uniparental runs don't accumulate an energy record for the male, so just push
      //   the starting energy
      if (energy_M.size() == 0) {
        endEnergy_M.push_back(pm.getEnergy());
        meanEnergy_M.push_back(pm.getEnergy());
        varEnergy_M.push_back(0);
      } else {
        endEnergy_M.push_back(energy_M[energy_M.size()-1]);			  // Final energy value (male)
			  meanEnergy_M.push_back(vectorMean(energy_M));				      // Arith. mean energy across season (male)
			  varEnergy_M.push_back(vectorVar(energy_M));					      // Variance in enegy across season (male)
      }

			std::vector<int> currIncubationBouts_F = pf.getIncubationBouts();	// Incubation bout lengths (female)
			std::vector<int> currForagingBouts_F = pf.getForagingBouts();		  // Foraging bout lengths (female)

			std::vector<int> currIncubationBouts_M = pm.getIncubationBouts();	// Incubation bout lengths (male)
			std::vector<int> currForagingBouts_M = pm.getForagingBouts();		  // Foraging bout lengths (male)

			meanIncubationBouts_F.push_back(vectorMean(currIncubationBouts_F));	// Arith. mean inc bout length (female)
			varIncubationBouts_F.push_back(vectorVar(currIncubationBouts_F));	 // Variance in inc bout length (female)

			meanForagingBouts_F.push_back(vectorMean(currForagingBouts_F));		// Arith. mean foraging bout length (female)
			varForagingBouts_F.push_back(vectorVar(currForagingBouts_F));		  // Variance in foraging bout length (female)

			meanIncubationBouts_M.push_back(vectorMean(currIncubationBouts_M)); // Arith. mean inc bout length (male)
			varIncubationBouts_M.push_back(vectorVar(currIncubationBouts_M));	 // Variance in inc bout length (male)

			meanForagingBouts_M.push_back(vectorMean(currForagingBouts_M));		// Arith. mean foraging bout length (male)
			varForagingBouts_M.push_back(vectorVar(currForagingBouts_M));		  // Variance in foraging bout length (male)
    }

    // Calculate Summary results across all iterations of parameter combos  		      // All summarized across all iterations for these parameters
    int numSuccess                = isolateHatchResults(hatchResults, "success");		  // # iteration successful hatch w/ living parents
    int numAllFail                = isolateHatchResults(hatchResults, "allFail");		  // # iterations where parent(s) died and egg failed
    int numParentFail             = isolateHatchResults(hatchResults, "parentFail");	// # iterations parent(s) died
    int numEggTimeFail            = isolateHatchResults(hatchResults, "eggTimeFail");	// # iterations parents lived but egg failed from time limit
    int numEggColdFail            = isolateHatchResults(hatchResults, "eggColdFail");	// # iterations parents lived but egg failed from consecutive neglect
    double meanHatchDays          = vectorMean(hatchDays);					                  // Arith. mean egg age (across iterations)
    double meanTotNeglect         = vectorMean(totNeglect);					                  // Arith. total neglect across season
    double meanMaxNeglect         = vectorMean(maxNeglect);					                  // Arith. mean maximum neglect streak
    double meanEndEnergy_F        = vectorMean(endEnergy_F);				                  // Arith. mean final energy (female)
    double meanMeanEnergy_F       = vectorMean(meanEnergy_F);				                  // Arith. mean of mean energies (female)
    double meanVarEnergy_F        = vectorMean(varEnergy_F);				                  // Arith. mean of variance in energy (female)
    double meanEndEnergy_M        = vectorMean(endEnergy_M);				                  // Arith. mean of final energy (male)
    double meanMeanEnergy_M       = vectorMean(meanEnergy_M);				                  // Arith. mean of mean energies (male)
    double meanVarEnergy_M        = vectorMean(varEnergy_M);				                  // Arith. mean of variance in energy (male)
    double meanMeanIncBout_F      = vectorMean(meanIncubationBouts_F);			          // Arith. mean of mean incubation bout length (female)
    double meanVarIncBout_F       = vectorMean(varIncubationBouts_F);			            // Arith. mean of variance in incubation bout lengths (female)
    double meanMeanForagingBout_F = vectorMean(meanForagingBouts_F);			            // Arith. mean of mean foraging bout length (female)
    double meanVarForagingBout_F  = vectorMean(varForagingBouts_F);				            // Arith. mean of variance in foraging bout length (female)
    double meanMeanIncBout_M      = vectorMean(meanIncubationBouts_M);			          // Arith. mean of mean incubation bout length (male)
    double meanVarIncBout_M       = vectorMean(varIncubationBouts_M);			            // Arith. mean of variance in incubation bout length (mmale)
    double meanMeanForagingBout_M = vectorMean(meanForagingBouts_M);			            // Arith. mean of mean foraging bout length (male)
    double meanVarForagingBout_M  = vectorMean(varForagingBouts_M);				            // Arith. mean of variance in foraging bout length (male)

   	// Write output in CSV formatted                // All summarized across all iterations for these parameters
		outfile << iterations << ","					          // Number of iterations for this parameter combo
				    << maxEnergyThresh_F << ","		          // Max energy threshold (satiation) for female parent
            << minEnergyThresh_F << ","		          // Min energy threshold (hunger) for female parent
            << maxEnergyThresh_M << ","		          // Max energy threshold (satiation) for male parent
            << minEnergyThresh_M << ","		          // Min energy threshold (hunger) for male parent
            << foragingMean << ","				          // Mean of foraging intake normal distribution for both parents
            << numSuccess << ","					          // # successful breeding iterations (egg hatched, both parents lived)
            << numAllFail << ","					          // # total failure iterations (egg died or failed to hatch, parent(s) died)
            << numParentFail << ","				          // # parent death iterations (one or both parents)
            << numEggTimeFail << ","			          // # egg hatch fail iterations (reached time limit, too much total neglect)
            << numEggColdFail << ","			          // # egg cold fail iterations (too much consecutive neglect)
            << meanHatchDays << ","				          // Mean egg age when season ended
            << meanTotNeglect << ","			          // Mean total neglect across the season
            << meanMaxNeglect << ","			          // Mean maximum neglect streak
            << meanEndEnergy_F << ","			          // Mean final energy (female)
            << meanMeanEnergy_F << ","		          // Mean of mean energy across season (female)
            << meanVarEnergy_F << ","			          // Mean of variance in energy across season (female)
            << meanEndEnergy_M << ","			          // Mean final energy (male)
            << meanMeanEnergy_M << ","		          // Mean of mean energy across season (male)
            << meanVarEnergy_M << ","			          // Mean of variance in energy across season (male)
            << meanMeanIncBout_F << ","		          // Mean of mean incubation bout length (female)
            << meanVarIncBout_F << ","		          // Mean of variance in incubation bout length (female)
            << meanMeanForagingBout_F << ","		    // Mean of mean foraging bout length (female)
            << meanVarForagingBout_F << ","			    // Mean of variance in foraging bout length (male)
            << meanMeanIncBout_M << ","				      // Mean of mean incubation bout length (male)
            << meanVarIncBout_M << ","				      // Mean of variance in incubation bout length (male)
            << meanMeanForagingBout_M << ","		    // Mean of mean foraging bout length (male)
            << meanVarForagingBout_M << std::endl;  // Mean of variance in foraging bout length (male)

		// Clear all output storage vectors for next param combo
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

	}	// ENDING PARAMETER LOOPS
	}
	}
	}
	}

	// Close file and exit
	outfile.close();
	std::cout << "Final output written to " << outfileName << "\n";
}

void breedingSeason_uni(Parent& pf, Parent& pm, Egg& egg)
{

	// The female pays the initial cost of the egg
	pf.setEnergy(pf.getEnergy() - egg.getEggCost());


	/*
	main breeding season loop, which ticks forward in DAYS
	Breeding season lasts until the egg hatches succesfully, or
 	if the egg hits the hard cut-off of incubation days due to
 	accumulated neglect
	*/
  while (!egg.isHatched() && (egg.getIncubationDays() <= egg.getMaxHatchDays())) {
		// Check if female is incubating
		bool incubated = false;
		if (pf.getState() == State::incubating) {
			incubated = true;
		}

		// Egg behavior based on incubation
		egg.eggDay(incubated);

		// Parent behavior, including state change
		pf.parentDay();
  }
}

void breedingSeason_semi(Parent& pf, Parent& pm, Egg& egg)
{

	// The female pays the initial cost of the egg
	pf.setEnergy(pf.getEnergy() - egg.getEggCost());

  pm.setSupplementalParent(true);

	/*
	main breeding season loop, which ticks forward in DAYS
	Breeding season lasts until the egg hatches succesfully, or
 	if the egg hits the hard cut-off of incubation days due to
 	accumulated neglect
	*/
  while (!egg.isHatched() && (egg.getIncubationDays() <= egg.getMaxHatchDays())) {
		// Check if female is incubating
		bool incubated = false;
		if (pf.getState() == State::incubating) {
			incubated = true;
		}

		// Egg behavior based on incubation
		egg.eggDay(incubated);

    // Male behavior, including foraging delivery
    pm.parentDay();
    double deliveredEnergy = pm.deliverEnergy();  // (can be 0)
    pf.receiveEnergy(deliveredEnergy);

		// Parent behavior, including state change
		pf.parentDay();
  }
}

void breedingSeason_bi(Parent& pf, Parent& pm, Egg& egg)
{

	// The female pays the initial cost of the egg
	pf.setEnergy(pf.getEnergy() - egg.getEggCost());

	/*
	main breeding season loop, which ticks forward in DAYS
	Breeding season lasts until the egg hatches succesfully, or
 	if the egg hits the hard cut-off of incubation days due to
 	accumulated neglect
	*/
  while (!egg.isHatched() && (egg.getIncubationDays() <= egg.getMaxHatchDays())) {

		// Check if either is incubating
		bool incubated = false;
		if (pf.getState() == State::incubating || pm.getState() == State::incubating) {

			incubated = true;
		}

		// Egg behavior based on incubation
		egg.eggDay(incubated);

		// Parent behavior, including state change
		pf.parentDay();
		pm.parentDay();

		/*
		If both parents are now incubating before the start of the
		next day, send the parent previously incubating away, while
		the newly arrived parent stays to incubate afresh
		*/
		if (pf.getState() == State::incubating && pm.getState() == State::incubating) {

			State previousFemaleState = pf.getPreviousDayState();
			State previousMaleState = pm.getPreviousDayState();

			// If the male has just returned, the female leaves
			if (previousFemaleState == State::incubating && previousMaleState == State::foraging) {
        pf.changeState();
			  pf.setDidOverlap(true);

			// If the female has just returned, the male leaves
			} else if (previousMaleState == State::incubating && previousFemaleState == State::foraging) {
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
