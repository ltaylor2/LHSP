#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <random>
#include <chrono>
#include <unistd.h>
#include <ctime>
#include <algorithm>

#include "Util.hpp"
#include "Egg.hpp"
#include "Parent.hpp"

static std::string OUTPUT_SUFFIX = "ms-1000iter";
static int ITERATIONS = 1000;

constexpr static double P_MIN_ENERGY_THRESH[] = {200, 1100, 100};
constexpr static double P_MAX_ENERGY_THRESH[] = {400, 1200, 100};

constexpr static double P_MIN_ENERGY_THRESH_EMPIRICAL[] = {400, 700, 100};
constexpr static double P_MAX_ENERGY_THRESH_EMPIRICAL[] = {700, 900, 100};

constexpr static double P_FORAGING_MEAN[] = {130, 170, 10};
constexpr static double P_FORAGING_SD[] = {0, 100, 10};

constexpr static int P_EGG_TOLERANCE_SHIFTED[] = {1, 7, 1};
constexpr static double P_EGG_COST_SHIFTED[] = {0, 500, 100};

// Need a single, static random generator device to let us only seed once
static std::mt19937* randGen;

// Function prototypes
void runModel(int iterations,
	          std::string outfileName,
	          std::vector<double> v_minEnergyThresh_f,
	          std::vector<double> v_maxEnergyThresh_f,
	          std::vector<double> v_minEnergyThresh_m,
	          std::vector<double> v_maxEnergyThresh_m,
	          std::vector<double> v_foragingMean,
	          std::vector<double> v_foragingSD,
			  std::vector<int> v_eggTolerance,
			  std::vector<double> v_eggCost,
			  bool oneParent, bool swapSexOrder);

std::string breedingSeason(Parent& pf, Parent& pm, Egg& egg, bool swapSexOrder);
std::string breedingSeason_oneParent(Parent& pf, Egg& egg);

int main()
{
    auto startTime = std::chrono::system_clock::now();

	// Seed static random generator device with ridiculous C++11 things
	auto seed = std::chrono::high_resolution_clock::now().time_since_epoch().count();
	std::mt19937 r = std::mt19937(seed);
	randGen = &r;

    // Output filename for this run
    std::time_t now = std::time(nullptr);

	// Generate a vector of parameter values from {min, max, by} arrays
	std::vector<double> v_minEnergyThresh_full         = paramVector(P_MIN_ENERGY_THRESH);
	std::vector<double> v_maxEnergyThresh_full         = paramVector(P_MAX_ENERGY_THRESH);
	std::vector<double> v_minEnergyThresh_empirical    = paramVector(P_MIN_ENERGY_THRESH_EMPIRICAL);
	std::vector<double> v_maxEnergyThresh_empirical    = paramVector(P_MAX_ENERGY_THRESH_EMPIRICAL);
	std::vector<double> v_foragingMean_full            = paramVector(P_FORAGING_MEAN);
	v_foragingMean_full.push_back(162.0);
	std::vector<double> v_foragingMean_concentrated    = paramVector(P_FORAGING_MEAN);
	std::vector<double> v_foragingMean_empirical       = paramVector(162.0);
	std::vector<double> v_foragingSD_full              = paramVector(P_FORAGING_SD);
	v_foragingSD_full.push_back(47.0);
	std::vector<double> v_foragingSD_empirical         = paramVector(47.0);
	std::vector<int> v_eggTolerance_empirical          = paramVector(7);
	std::vector<int> v_eggTolerance_shifted            = paramVector(P_EGG_TOLERANCE_SHIFTED);
	std::vector<double> v_eggCost_empirical            = paramVector(69.7);
	std::vector<double> v_eggCost_shifted              = paramVector(P_EGG_COST_SHIFTED);

	std::cout << "\n\n\nBeginning regular model runs\n\n\n";
	std::string outfileName_regular = std::string("../Output/sims_regular_") + OUTPUT_SUFFIX + std::string(".csv");
    runModel(ITERATIONS, 
             outfileName_regular, 
             v_minEnergyThresh_full, 
             v_maxEnergyThresh_full, 
             v_minEnergyThresh_full, 
             v_maxEnergyThresh_full, 
             v_foragingMean_full,
			 v_foragingSD_full,
			 v_eggTolerance_empirical, 
			 v_eggCost_empirical,
			 false, false);

	std::cout << "\n\n\nDone with regular models.\nBeginning egg tolerance runs.\n\n\n";
	std::string outfileName_eggTolerance = std::string("../Output/sims_eggTolerance_") + OUTPUT_SUFFIX + std::string(".csv");
	runModel(ITERATIONS, 
             outfileName_eggTolerance, 
             v_minEnergyThresh_empirical, 
             v_maxEnergyThresh_empirical, 
             v_minEnergyThresh_empirical, 
             v_maxEnergyThresh_empirical,
             v_foragingMean_concentrated,
			 v_foragingSD_empirical,
			 v_eggTolerance_shifted,
			 v_eggCost_empirical,
			 false, false);

	std::cout << "\n\n\nDone with egg tolerance models.\nBeginning egg cost runs.\n\n\n";
	std::string outfileName_eggCost = std::string("../Output/sims_eggCost_") + OUTPUT_SUFFIX + std::string(".csv");
	runModel(ITERATIONS, 
             outfileName_eggCost, 
             v_minEnergyThresh_empirical, 
             v_maxEnergyThresh_empirical,
             v_minEnergyThresh_empirical, 
             v_maxEnergyThresh_empirical, 
             v_foragingMean_empirical,
			 v_foragingSD_empirical,
			 v_eggTolerance_empirical,
			 v_eggCost_shifted,
			 false, false);

	std::cout << "\n\n\nDone with egg cost models.\nBeginning swapped sex order model.\n\n\n";
	std::string outfileName_swapSexOrder = std::string("../Output/sims_swapSexOrder_") + OUTPUT_SUFFIX + std::string(".csv");
	runModel(ITERATIONS, 
             outfileName_swapSexOrder, 
             v_minEnergyThresh_empirical,
             v_maxEnergyThresh_empirical,
             v_minEnergyThresh_empirical, 
             v_maxEnergyThresh_empirical, 
             v_foragingMean_empirical,
			 v_foragingSD_empirical,
			 v_eggTolerance_empirical,
			 v_eggCost_empirical,
			 false, true);
						  
	std::cout << "\n\n\nDone with swapped sex order models.\nBeginning one parent model.\n\n\n";
	std::string outfileName_oneParent = std::string("../Output/sims_oneParent_") + OUTPUT_SUFFIX + std::string(".csv");
	std::vector<double> v_dummyMale_min(1, 0.0);
	std::vector<double> v_dummyMale_max(1, 1.0);
	static double p_foraging_mean_wider[] = {130, 400, 10};
	std::vector<double> v_foragingMean_wider = paramVector(p_foraging_mean_wider);
	runModel(ITERATIONS, 
             outfileName_oneParent, 
             v_minEnergyThresh_empirical,
             v_maxEnergyThresh_empirical,
             v_dummyMale_min, 
             v_dummyMale_max, 
             v_foragingMean_wider,
			 v_foragingSD_empirical,
			 v_eggTolerance_empirical,
			 v_eggCost_empirical,
			 true, false);

	std::cout << "Ended model runs\n";

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
	          std::string outfileName,
	          std::vector<double> v_minEnergyThresh_f,
              std::vector<double> v_maxEnergyThresh_f,
			  std::vector<double> v_minEnergyThresh_m,
              std::vector<double> v_maxEnergyThresh_m,
	          std::vector<double> v_foragingMean,
			  std::vector<double> v_foragingSD,
			  std::vector<int> v_eggTolerance,
			  std::vector<double> v_eggCost,
			  bool oneParent, bool swapSexOrder)
{
    
	// Start formatted output
	std::ofstream outfile;
	outfile.open(outfileName, std::ofstream::trunc);

	// Header column for CSV format
	outfile << "Iteration" << ","
            << "Min_Energy_Thresh_F" << ","
			<< "Max_Energy_Thresh_F" << ","
            << "Min_Energy_Thresh_M" << ","
			<< "Max_Energy_Thresh_M" << ","
			<< "Foraging_Condition_Mean" << ","
            << "Foraging_Condition_SD" << ","
			<< "Egg_Tolerance" << ","
			<< "Egg_Cost" << ","
			<< "Num_Parents" << ","
	    	<< "Hatch_Result" << ","
			<< "Hatch_Days" << ","
			<< "Total_Neglect" << ","
			<< "Max_Neglect" << ","
			<< "End_Energy_F" << ","
			<< "Mean_Energy_F" << ","
			<< "Var_Energy_F" << ","
			<< "Dead_F" << ","
			<< "End_Energy_M" << ","
			<< "Mean_Energy_M" << ","
			<< "Var_Energy_M" << ","
			<< "Dead_M" <<  ","
            << "Season_Length" << ","
            << "Season_History" << std::endl;

	/*
	Total parameter space being searched
	NOTE we throw out any combinations where
	     minEnergy [hunger] > maxEnergy [satiation],
	     So this space is reduced to that array
	*/

    int energyCombinations = 0;
    for (unsigned int i = 0; i < v_minEnergyThresh_f.size(); i++) {
        for (unsigned int j = 0; j < v_maxEnergyThresh_f.size(); j++) {
			for (unsigned int x = 0; x < v_minEnergyThresh_m.size(); x++) {
				for (unsigned int y = 0; y < v_maxEnergyThresh_m.size(); y++) {
            		double minThresh_f = v_minEnergyThresh_f[i];
            		double maxThresh_f = v_maxEnergyThresh_f[j];
            		double minThresh_m = v_minEnergyThresh_m[x];
            		double maxThresh_m = v_maxEnergyThresh_m[y];
            		if (maxThresh_f > minThresh_f && maxThresh_m > minThresh_m) {
            		    energyCombinations++;
	} } } } }

	int totParamIterations = energyCombinations *
							 v_foragingMean.size() * 
							 v_foragingSD.size() *
							 v_eggTolerance.size() *
							 v_eggCost.size();

    std::cout << "Estimated parameter combinations: " << totParamIterations << std::endl;
	int currParamIteration = 0;

	// For every minEnergy value (FEMALE)
	for (unsigned int a = 0; a < v_minEnergyThresh_f.size(); a++) {
	    double minEnergyThresh_F = v_minEnergyThresh_f[a];

	// (then) for every maxEnergy value (FEMALE)
	for (unsigned int b = 0; b < v_maxEnergyThresh_f.size(); b++) {
		double maxEnergyThresh_F = v_maxEnergyThresh_f[b];

	// (then) for every minEnergy value (MALE)
	for (unsigned int c = 0; c < v_minEnergyThresh_m.size(); c++) {
        double minEnergyThresh_M = v_minEnergyThresh_m[c];

	// (then) for every maxEnergy value (MALE)
	for (unsigned int d = 0; d < v_maxEnergyThresh_m.size(); d++) {
		double maxEnergyThresh_M = v_maxEnergyThresh_m[d];

	// Skip if hunger threshold >= satiation threshold(doesn't make sense!)
	if (minEnergyThresh_F >= maxEnergyThresh_F || minEnergyThresh_M >= maxEnergyThresh_M) {
        continue; 
    }

	// (then, then) for every foraging mean value
	for (unsigned int e = 0; e < v_foragingMean.size(); e++) {
		double foragingMean = v_foragingMean[e];
    
	for (unsigned int f = 0; f < v_foragingSD.size(); f++) {
		double foragingSD = v_foragingSD[f];

	// egg variables
	for (unsigned int g = 0; g < v_eggTolerance.size(); g++) {
		int eggTolerance = v_eggTolerance[g];

	for (unsigned int h = 0; h < v_eggCost.size(); h++) {
		double eggCost = v_eggCost[h];

		// Mildly helpful progress update
		currParamIteration++;
		int progressStep = std::max(1, totParamIterations / 100);
		if (currParamIteration % progressStep == 0) {
			std::cout << "[ofstream flushed] Approximate progress of "
					  << outfileName
					  << ": "
					  << round((double)currParamIteration / totParamIterations*100) << "%" << std::endl;
            outfile.flush();
		}

        // Replicate every parameter combination by i iterations
        for (int i = 0; i < iterations; i++) {

            // A fresh egg
            Egg egg = Egg();
			egg.setNeglectMax(eggTolerance);
			egg.setEggCost(eggCost);

            // Two shiny new parents
            Parent pf = Parent(Sex::female, randGen);
            Parent pm = Parent(Sex::male, randGen);

            // Set both parent's parameters according to the new combo  
            pf.setMinEnergyThresh(minEnergyThresh_F);
            pf.setMaxEnergyThresh(maxEnergyThresh_F);
            pf.setForagingDistribution(foragingMean, foragingSD);   
            
            pm.setMinEnergyThresh(minEnergyThresh_M);
            pm.setMaxEnergyThresh(maxEnergyThresh_M);
            pm.setForagingDistribution(foragingMean, foragingSD);

            // Run the given breeding season model function
			std::string seasonHistory = "";
			if (oneParent) {
				seasonHistory = breedingSeason_oneParent(pf, egg);
			} else {
            	seasonHistory = breedingSeason(pf, pm, egg, swapSexOrder);
			}

            // Extract output
			std::string hatchResult = "";
			if (oneParent) {
				hatchResult = checkSeasonSuccess(pf, egg);
				pm.parentDay();
			} else {
				hatchResult = checkSeasonSuccess(pf, pm, egg);
			}

            double hatchDays = egg.getIncubationDays();                 // Total number of days (maybe limit)
            int totNeglect = egg.getTotNeg();				            // Total neglect across season
            int maxNeglect = egg.getMaxNeg();				            // Maximum neglect streak

            std::vector<double> energy_F = pf.getEnergyRecord();
			double endEnergy_F = -1;
			double meanEnergy_F = -1;
			double varEnergy_F = -1;
			if (energy_F.size() > 0) {
				endEnergy_F = energy_F[energy_F.size()-1];           // Final energy value (female)
            	meanEnergy_F = vectorMean(energy_F);                 // Arithmetic mean energy across season (female)
            	varEnergy_F = vectorVar(energy_F);                   // Variance in energy across season (female)
			}
            bool dead_F = !pf.isAlive();                             // Is the female alive?

            std::vector<double> energy_M = pm.getEnergyRecord(); 
			double endEnergy_M = -1;
			double meanEnergy_M = -1;
			double varEnergy_M = -1;
			if (energy_M.size() > 0) {
				endEnergy_M = energy_M[energy_M.size()-1];           // Final energy value (male)
            	meanEnergy_M = vectorMean(energy_M);                 // Arithmetic mean energy across season (male)
            	varEnergy_M = vectorVar(energy_M);                   // Variance in energy across season (male)
			}
            bool dead_M = !pm.isAlive();                             // Is the male alive?

            int seasonLength = egg.getIncubationDays();

			int numParents = 2;
			if (oneParent) {
				numParents = 1;
			}
            // Send formatted output
            outfile << i << ","
                    << minEnergyThresh_F << ","
                    << maxEnergyThresh_F << ","
                    << minEnergyThresh_M << ","
                    << maxEnergyThresh_M << ","
                    << foragingMean << ","
                    << foragingSD << ","
					<< eggTolerance << ","
					<< eggCost << ","
					<< numParents << ","
                    << hatchResult << ","
                    << hatchDays << ","
                    << totNeglect << ","
                    << maxNeglect << ","
                    << endEnergy_F << ","
                    << meanEnergy_F << ","
                    << varEnergy_F << ","
                    << dead_F << ","
                    << endEnergy_M << ","
                    << meanEnergy_M << ","
                    << varEnergy_M << ","
                    << dead_M << ","
                    << seasonLength << ","
                    << seasonHistory << std::endl;
        }
    } } } } } } } } // End parameter loops

	// Close file and exit
	outfile.close();
	std::cout << "Final output written to " << outfileName << "\n";
}

std::string breedingSeason(Parent& pf, Parent& pm, Egg& egg, bool swapSexOrder)
{
    // Season history that records state at the end of each day
    std::string seasonHistory = ""; 

	// The female pays the initial cost of the egg
	pf.setEnergy(pf.getEnergy() - egg.getEggCost());

	if (swapSexOrder) {
		// If requested, swap females to begin foraging, and males to begin incubating
		pf.setState(State::foraging);
		pf.setPrevDayState(State::foraging);
		
		pm.setState(State::incubating);
		pm.setPrevDayState(State::incubating);
	}

	/*
	main breeding season loop, which ticks forward in DAYS
	Breeding season lasts until the egg hatches succesfully, or
 	if the egg hits the hard cut-off of incubation days due to
 	accumulated neglect
	*/
    while (egg.isAlive() && !egg.isHatched() && (egg.getIncubationDays() <= egg.getMaxHatchDays())) {

		// Check if either is incubating
		bool incubated = false;

		State femaleStartState = pf.getState();
        State maleStartState = pm.getState();
		        
        // Add the daily start state to the season history
        if (femaleStartState == State::incubating) { seasonHistory += 'F'; }
        else if (maleStartState == State::incubating) { seasonHistory += 'M'; }
        else { seasonHistory += 'N'; }

		// Egg behavior based on incubation
		if (femaleStartState == State::incubating || maleStartState == State::incubating) {
			incubated = true;
		}
		egg.eggDay(incubated);

		// Parent behavior, including state change
		pf.parentDay();
		pm.parentDay();

        State femaleState = pf.getState();
        State maleState = pm.getState();

        if (femaleState == State::dead || maleState == State::dead) {
            break;
        }

		if (femaleState == State::incubating && maleState == State::incubating) {

			State previousFemaleState = pf.getPreviousDayState();
			State previousMaleState = pm.getPreviousDayState();

			/*
			 If the male has just returned, the female leaves
			 If the female has just returned, the male leaves
			 On the rare occasion where both individuals switch from
			 foraging to incubating simultaenously in a timestep,
			 a random parent is sent to switch
			*/
			if (previousFemaleState == State::incubating && previousMaleState == State::foraging) {
                pf.changeState();
			} else if (previousMaleState == State::incubating && previousFemaleState == State::foraging) {
				pm.changeState();
			} else {
				std::uniform_real_distribution<double> tieBreaker(0.0, 1.0);
  				if (tieBreaker(*randGen) <= 0.5) {
					pf.changeState();
				} else {
					pm.changeState();
				}
			}
		}
	}

    return seasonHistory;
}

std::string breedingSeason_oneParent(Parent& pf, Egg& egg)
{
    // Season history that records state at the end of each day
    std::string seasonHistory = ""; 

	// The female pays the initial cost of the egg
	pf.setEnergy(pf.getEnergy() - egg.getEggCost());

	while (egg.isAlive() && !egg.isHatched() && (egg.getIncubationDays() <= egg.getMaxHatchDays())) {

        State femaleStartState = pf.getState();

		// Add the daily start state to the season history
        if (femaleStartState == State::incubating) { seasonHistory += 'F'; }
        else { seasonHistory += 'N'; }

		// Check if either is incubating
		bool incubated = false;
		if (femaleStartState == State::incubating) {
			incubated = true;
		}

		// Egg behavior based on incubation
		egg.eggDay(incubated);

		// Parent behavior, including state change
		pf.parentDay();

		// Check for death
        State femaleState = pf.getState();
        if (femaleState == State::dead) {
            break;
        }

	}

    return seasonHistory;
}