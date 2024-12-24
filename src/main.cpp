#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <random>
#include <chrono>
#include <unistd.h>
#include <ctime>

#include "Util.hpp"
#include "Egg.hpp"
#include "Parent.hpp"

static std::string OUTPUT_SUFFIX = "";
static int ITERATIONS = 1000;

constexpr static double P_MAX_ENERGY_THRESH[] = {200, 1000, 100};
constexpr static double P_MIN_ENERGY_THRESH[] = {200, 1000, 100};
constexpr static double P_FORAGING_MEAN[] = {130, 170, 10};

// Need a single, static random generator device to let us only seed once
static std::mt19937* randGen;

// Function prototypes
void runModel(int iterations,
	          std::string outfileName,
	          std::vector<double> v_minEnergyThresh,
	          std::vector<double> v_maxEnergyThresh,
	          std::vector<double> v_foragingMean);

std::string breedingSeason(Parent& pf, Parent& pm, Egg& egg, bool kick);

int main()
{
    auto startTime = std::chrono::system_clock::now();

	// Seed static random generator device with ridiculous C++11 things
	auto seed = std::chrono::high_resolution_clock::now().time_since_epoch().count();
	std::mt19937 r = std::mt19937(seed);
	randGen = &r;

    // Output filename for this run
    std::time_t now = std::time(nullptr);
    char timeStr[100];
    std::strftime(timeStr, sizeof(timeStr), "%Y-%m-%d_%H-%M-%S", std::localtime(&now));
    std::string outfileName = std::string("../Output/sims_") + timeStr + std::string("_") + OUTPUT_SUFFIX + std::string(".csv");

	// Generate a vector of parameter values from {min, max, by} arrays
	std::vector<double> v_minEnergyThresh = paramVector(P_MIN_ENERGY_THRESH);
	std::vector<double> v_maxEnergyThresh = paramVector(P_MAX_ENERGY_THRESH);
	std::vector<double> v_foragingMean    = paramVector(P_FORAGING_MEAN);

	std::cout << "\n\n\nBeginning model runs\n\n\n";

    runModel(ITERATIONS, 
             outfileName, 
             v_minEnergyThresh, 
             v_maxEnergyThresh, 
             v_foragingMean);

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
	          std::vector<double> v_minEnergyThresh,
              std::vector<double> v_maxEnergyThresh,
	          std::vector<double> v_foragingMean)
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
            << "Foraging_Condition_Kick" << ","
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
	NOTE I throw out any combinations where
	minEnergy [hunger] > maxEnergy [satiation],
	So this space is reduced to that array
	*/

    int energyCombinations = 0;
    for (unsigned int i = 0; i < v_minEnergyThresh.size(); i++) {
        for (unsigned int j = 0; j < v_maxEnergyThresh.size(); j++) {
            double minThresh = v_minEnergyThresh[i];
            double maxThresh = v_maxEnergyThresh[j];
            if (maxThresh > minThresh) {
                energyCombinations++;
            }
        }
    }

	int totParamIterations = energyCombinations * energyCombinations * v_foragingMean.size();

	int currParamIteration = 0;

	// For every minEnergy value (FEMALE)
	for (unsigned int a = 0; a < v_minEnergyThresh.size(); a++) {
	    double minEnergyThresh_F = v_minEnergyThresh[a];

	// (then) for every maxEnergy value (FEMALE)
	for (unsigned int b = 0; b < v_maxEnergyThresh.size(); b++) {
		double maxEnergyThresh_F = v_maxEnergyThresh[b];

	// (then) for every minEnergy value (MALE)
	for (unsigned int c = 0; c < v_minEnergyThresh.size(); c++) {
        double minEnergyThresh_M = v_minEnergyThresh[c];

	// (then) for every maxEnergy value (MALE)
	for (unsigned int d = 0; d < v_maxEnergyThresh.size(); d++) {
		double maxEnergyThresh_M = v_maxEnergyThresh[d];

	// Skip if hunger threshold >= satiation threshold(doesn't make sense!)
	if (minEnergyThresh_F >= maxEnergyThresh_F || minEnergyThresh_M >= maxEnergyThresh_M) {
        continue; 
    }

	// (then, then) for every foraging mean value
	for (unsigned int e = 0; e < v_foragingMean.size(); e++) {
		double foragingMean = v_foragingMean[e];
    
		// Mildly helpful progress update
		currParamIteration++;
		if (currParamIteration % (totParamIterations/100) == 0) {
			std::cout << "[ofstream flushed] Approximate progress of "
					  << outfileName
					  << ": "
					  << round((double)currParamIteration / totParamIterations*100) << "%" << std::endl;
            outfile.flush();
		}

    // (finally) we're duplicating each run for an added "kick"
    for (int k = 0; k < 2; k++) {
        bool kick = false;
        if (k % 2 == 1) { kick = true; }

        // Replicate every parameter combination by i iterations
        for (int i = 0; i < iterations; i++) {

            // A fresh egg
            Egg egg = Egg();

            // Two shiny new parents
            Parent pf = Parent(Sex::female, randGen);
            Parent pm = Parent(Sex::male, randGen);

            // Set both parent's parameters according to the new combo  
            pf.setMinEnergyThresh(minEnergyThresh_F);
            pf.setMaxEnergyThresh(maxEnergyThresh_F);
            pf.setForagingDistribution(foragingMean, pf.getForagingSD());   
            
            pm.setMinEnergyThresh(minEnergyThresh_M);
            pm.setMaxEnergyThresh(maxEnergyThresh_M);
            pm.setForagingDistribution(foragingMean, pm.getForagingSD());

            //
            // Run the given breeding season model function
            std::string seasonHistory = breedingSeason(pf, pm, egg, kick);
            //
            //

            // Extract output
            double foragingSD = pf.getForagingSD();

            std::string hatchResult = checkSeasonSuccess(pf, pm, egg);	// Factorized season result
            double hatchDays = egg.getIncubationDays();                 // Total number of days (maybe limit)
            int totNeglect = egg.getTotNeg();				            // Total neglect across season
            int maxNeglect = egg.getMaxNeg();				            // Maximum neglect streak

            std::vector<double> energy_F = pf.getEnergyRecord();
            double endEnergy_F = energy_F[energy_F.size()-1];           // Final energy value (female)
            double meanEnergy_F = vectorMean(energy_F);                 // Arithmetic mean energy across season (female)
            double varEnergy_F = vectorVar(energy_F);                   // Variance in energy across season (female)
            bool dead_F = !pf.isAlive();                                // Is the female alive?

            std::vector<double> energy_M = pm.getEnergyRecord(); 
            double endEnergy_M = energy_M[energy_M.size()-1];           // Final energy value (male)
            double meanEnergy_M = vectorMean(energy_M);                 // Arithmetic mean energy across season (male)
            double varEnergy_M = vectorVar(energy_M);                   // Variance in energy across season (male)
            bool dead_M = !pm.isAlive();                                // Is the male alive?

            int seasonLength = egg.getIncubationDays();

            // Send formatted output
            outfile << i << ","
                    << minEnergyThresh_F << ","
                    << maxEnergyThresh_F << ","
                    << minEnergyThresh_M << ","
                    << maxEnergyThresh_M << ","
                    << foragingMean << ","
                    << foragingSD << ","
                    << kick << ","
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
    } }	} } } } // End parameter loops

	// Close file and exit
	outfile.close();
	std::cout << "Final output written to " << outfileName << "\n";
}

std::string breedingSeason(Parent& pf, Parent& pm, Egg& egg, bool kick)
{
    // Record the foraging parameters to restore later
    double foragingMean_F_original = pf.getForagingMean();
    double foragingSD_F_original = pf.getForagingSD();
    
    double foragingMean_M_original = pm.getForagingMean();
    double foragingSD_M_original = pm.getForagingSD();

    // Season history that records state at the end of each day
    std::string seasonHistory = ""; 

	// The female pays the initial cost of the egg
	pf.setEnergy(pf.getEnergy() - egg.getEggCost());

	/*
	main breeding season loop, which ticks forward in DAYS
	Breeding season lasts until the egg hatches succesfully, or
 	if the egg hits the hard cut-off of incubation days due to
 	accumulated neglect
	*/

    while (!egg.isHatched() && (egg.getIncubationDays() <= egg.getMaxHatchDays())) {

        // if there is a kick in the season, kick the foraging environment for days 20-23
        if (kick) {
            if (egg.getIncubationDays() == 20) {
                pf.setForagingDistribution(0, 0);
                pm.setForagingDistribution(0, 0);
            } else if (egg.getIncubationDays() >= 23){
                pf.setForagingDistribution(foragingMean_F_original, foragingSD_F_original);
                pm.setForagingDistribution(foragingMean_M_original, foragingSD_M_original);
            }
        }

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

        State femaleState = pf.getState();
        State maleState = pm.getState();

        if (femaleState == State::dead || maleState == State::dead) {
            break;
        }

		if (femaleState == State::incubating && maleState == State::incubating) {

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
        
        // Add the daily state to the season history
        if (femaleState == State::incubating) { seasonHistory += 'F'; }
        else if (maleState == State::incubating) { seasonHistory += 'M'; }
        else { seasonHistory += 'N'; }
	}

    // with the season over, reset the foraging mean for the output records 
    // in case the parents died in the middle of the kick
    // (otherwise they might get recorded as foraging mean of 0, if the season ended in the middle of the kick)
    if (kick) {
        pf.setForagingDistribution(foragingMean_F_original, foragingSD_F_original);
        pm.setForagingDistribution(foragingMean_M_original, foragingSD_M_original);
    }

    return seasonHistory;
}