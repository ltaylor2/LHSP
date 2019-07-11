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

// TODO Make key global constants cmd line input parameters

// The number of iterations for each model or parameter set of a given model
constexpr static int ITERATIONS = 10000;

// Unique (will overwrite) output file for each model run,
// Sent to runModel()
constexpr static char OUTPUT_FNAME_STANDARD[] = "sims_standard.txt";
constexpr static char OUTPUT_FNAME_OVERLAPRAND[] = "sims_overlapRand.txt";
constexpr static char OUTPUT_FNAME_NOOVERLAP[] = "sims_noOverlap.txt";
constexpr static char OUTPUT_FNAME_COMPENSATE[] = "sims_compensate.txt";
constexpr static char OUTPUT_FNAME_COMPENSATE2[] = "sims_compensate2.txt";
constexpr static char OUTPUT_FNAME_RETALIATE[] = "sims_retaliate.txt";
constexpr static char OUTPUT_FNAME_RETALIATE2[] = "sims_retaliate2.txt";

// Vectors that define the {min, max, by} values for 
// The sequence of parameters to check.
// Use utility function paramVector() to construct a sequence of values
// and then send to runModel()
constexpr static double P_MAX_ENERGY_THRESH[] = {0, 1000, 50};
constexpr static double P_MIN_ENERGY_THRESH[] = {0, 1000, 50};
constexpr static double P_FORAGING_MEAN[] = {130, 160, 3};

// Need a single, static random generator device to let us only seed once
static std::mt19937* randGen;

/*
Master function to call each model and write formatted output
@param iterations the number of breeding season replicates
@param modelFunc ptr to model function itself to call directly
@param outfileName file to write output
@param v_maxEnergyThresh vector of satiation thresholds to test
@param v_minEnergyThresh vector of hunger thresholds to test
@param v_foragingMean vector of mean foraging intake values to test
*/
void runModel(int iterations, 
	      void (*modelFunc)(Parent&, Parent&, Egg&), 
	      std::string outfileName,
	      std::vector<double> v_maxEnergyThresh,
	      std::vector<double> v_minEnergyThresh,
	      std::vector<double> v_foragingMean);
/* 
The standard breeding season where two parents
manage their energy levels across foraging and incubating states.
Parents lose energy while incubating (i.e., metabolism) and switch
to foraging when their energy drops below their minEnergy threshold (hunger).
Parents lose MORE energy per day while foraging (i.e., heightened metabolism),
but have the chance to gain energy by sampling from a normal distribution
of foraging intake values with some characteristic mean and variance. 
Parents switch from foraging to incubation when their energy rises above their
maxEnergy threshold (satiation).

If both parents overlap in incubation (e.g., one parent reaches its satiation threshold
before its incubating mate drops below its hunger threshold), the parent that was 
previously incubating will leave to forage regardless of its energy level.

Meanwhile, the egg sits in the nest. When at least one parent is incubating,
it moves towards its hatch date. When neither parent is incubating, it 
accumulates neglect. Each day of neglect adds to the total required time 
to hatch, and too much consecutive neglect will kill the egg outright.
@param pf female adult breeder
@param pm male adult breeder
@param egg the egg in the burrow
*/
void breedingSeason(Parent& pf, Parent& pm, Egg& egg);

/*
The same as the standard breeding season, except when parents overlap
in the burrow a RANDOM mate switches (rather than orderly switching)
@param pf female adult breeder
@param pm male adult breeder
@param egg the egg in the burrow
*/
void breedingSeason_overlapRand(Parent& pf, Parent& pm, Egg& egg) ;

/*
A breeding season where parents ignore one another (i.e., no overlap rule).
Parents acting like particles ignoring each other and doing their own thing
based on their energetic rules.
@param pf female adult breeder
@param pm male adult breeder
@param egg the egg in the burrow
*/
void breedingSeason_noOverlap(Parent& pf, Parent& pm, Egg& egg);

/*
Breeding season with compensation,
where a parent will stay an extra incubation day on incubation bout
I+1 if they did not leave because of an overlap switch in incubation
bout I. In other words, if they were left to reach their hunger threshold 
on their previous incubation bout, they will compensate for one addition day.
Parents still stop incubation if their mate returns to overlap on incubation
bout I+1.
@param pf female adult breeder
@param pm male adult breeder
@param egg the egg in the burrow
*/
void breedingSeason_compensate(Parent& pf, Parent& pm, Egg& egg);

/*
Breeding season with compensation*2,
(see call to breedingSeason_compensate(), which calls breedingSeason()). 
A parent will stay an extra TWO incubation days on incubation bout I+1
if they did not leave because of an overlap switch in incubation bout I.
@param pf female adult breeder
@param pm male adult breeder
@param egg the egg in the burrow
*/
void breedingSeason_compensate2(Parent&, Parent&, Egg&);

/*
Breeding season with retaliation,
where a parent will stay an extra foraging day on the foraging bout
following an incubation bout where they were not relieved by their partner.
@param pf female adult breeder
@param pm male adult breeder
@param egg the egg in the burrow
*/
void breedingSeason_retaliate(Parent& pf, Parent& pm, Egg& egg);

/*
Breeding season with retaliation*2,
(see call to breedingSeason_retaliate(), which calls breedingSeason()).
A parent will stay an extra TWO foraging days on the foraging bout
following an incubation bout where they were not relieved by their partner.
@param pf female adult breeder
@param pm male adult breeder
@param egg the egg in the burrow
*/
void breedingSeason_retaliate2(Parent& pf, Parent& pm, Egg& egg);

/*
Called when program is run.
Calls each individual model with runModel(), which 
takes the address of the correct behavioral breeding season model
as its second parameter.
Make sure to send the correct OUTPUT_FNAME to each runModel() call!
*/
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
	std::vector<double> v_foragingMean = paramVector(P_FORAGING_MEAN);

	std::cout << "Beginning STANDARD model run" << std::endl;

	// Standard breeding season
	runModel(ITERATIONS, 
		 *breedingSeason, 
		 OUTPUT_FNAME_STANDARD,
		 v_maxEnergyThresh,
		 v_minEnergyThresh,
		 v_foragingMean);

	std::cout << std::endl << "Done with STANDARD model run" << std::endl;
	std::cout << "Beginning OVERLAP_RAND model run\n\n";

	// Breeding season where partners switch randomly upon overlap
	runModel(ITERATIONS, 
		 *breedingSeason_overlapRand, 
		 OUTPUT_FNAME_OVERLAPRAND,
		 v_maxEnergyThresh,
		 v_minEnergyThresh,
		 v_foragingMean);

	std::cout << std::endl << "Done with OVERLAP_RAND model run" << std::endl;
	std::cout << "Beginning NO_OVERLAP model run\n\n";

	/*
	Breeding season where partners ignore one another,
	just going about their business
	*/
	runModel(ITERATIONS, 
			 *breedingSeason_noOverlap,
			 OUTPUT_FNAME_NOOVERLAP,
			 v_maxEnergyThresh,
			 v_minEnergyThresh,
			 v_foragingMean);

	std::cout << std::endl << "Done with NO_OVERLAP model run" << std::endl;
	std::cout << "Beginning COMPENSATION model run" << "\n\n";

	/*
	Breeding season where a mate compensates (for one day)
	by incubating longer iff its partner did not overlap last
	incubation bout
	*/
	runModel(ITERATIONS, 
		 *breedingSeason_compensate, 
		 OUTPUT_FNAME_COMPENSATE,
		 v_maxEnergyThresh,
		 v_minEnergyThresh,
		 v_foragingMean);

	std::cout << "\n" << "Done with COMPENSATION model run\n";
	std::cout << "Beginning COMPENSATION*2 model run" << "\n\n";

	// Compensation but for two days instead of one
	runModel(ITERATIONS, 
			 *breedingSeason_compensate2, 
			 OUTPUT_FNAME_COMPENSATE2,
			 v_maxEnergyThresh,
			 v_minEnergyThresh,
			 v_foragingMean);


	std::cout << "\n" << "Done with COMPENSATION*2 model run\n";
	std::cout << "Beginning RETALIATION model run" << "\n\n";

	/*
	Breeding season where a mate retaliates (for one day)
	by foraging longer iff its partner did not overlap laste
	incubation bout 
	*/ 
	runModel(ITERATIONS, 
		 *breedingSeason_retaliate, 
		 OUTPUT_FNAME_RETALIATE,
		 v_maxEnergyThresh,
		 v_minEnergyThresh,
		 v_foragingMean);

	std::cout << "\n" << "Done with RETALIATION model run\n";
	std::cout << "Beginning RETALIATION*2 model run" << "\n\n";

	// Retaliation but for two days instead of one
	runModel(ITERATIONS, 
		 *breedingSeason_retaliate2, 
		 OUTPUT_FNAME_RETALIATE2,
		 v_maxEnergyThresh,
		 v_minEnergyThresh,
		 v_foragingMean);

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
	std::vector<double> varForagingBouts_M   = std::vector<double>();

	/*
	Total parameter space being searched
	NOTE I throw out any combinations where 
	minEnergy [hunger] > maxEnergy [satiation],
	So this space is reduced to that array 
	*/
	int totParamIterations = v_maxEnergyThresh.size() * 
				 v_minEnergyThresh.size() * 
				 v_foragingMean.size();
	int paramIteration = 1;	// current parameter information

	// For every maxEnergy vvalue
	for (unsigned int a = 0; a < v_maxEnergyThresh.size(); a++) {
		double maxEnergyThresh = v_maxEnergyThresh[a];

	// (then) for every minEnergy value
	for (unsigned int b = 0; b < v_minEnergyThresh.size(); b++) {
	    double minEnergyThresh = v_minEnergyThresh[b];

	// (then, then) for every foraging mean value
	for (unsigned int c = 0; c < v_foragingMean.size(); c++) {
		double foragingMean = v_foragingMean[c];

		// This is one set of parameters to test
	    paramIteration++;	

	    // Skip if hunger >= satiation (doesn't make sense!)
	    if (minEnergyThresh >= maxEnergyThresh) {
	      	continue;
	    }
	    
	    // Helpful output, but not TOO helpful
		if (paramIteration % (totParamIterations/100) == 0) {
			std::cout << "Searching parameter space of size " 
		                  << totParamIterations
		                  << " on combo " << paramIteration
		                  << " (" << iterations << " iters per combo)\n";
		}

		// Replicate every parameter combination by i iterations
        for (int i = 0; i < iterations; i++) {

        	// A fresh eggs
        	Egg egg = Egg();

        	// Two shiny new parents, one male and one female
			Parent pf = Parent(Sex::female, randGen);
			Parent pm = Parent(Sex::male, randGen);

			// Set both parent's parameters according to the new combo
			pf.setMaxEnergyThresh(maxEnergyThresh);
			pf.setMinEnergyThresh(minEnergyThresh);
			pf.setForagingDistribution(foragingMean, pf.getForagingSD());
			pm.setMaxEnergyThresh(maxEnergyThresh);
			pm.setMinEnergyThresh(minEnergyThresh);
			pm.setForagingDistribution(foragingMean, pm.getForagingSD());

			// Run the given breeding season model function,
			modelFunc(pf, pm, egg);

			// Add this iteration's results to the parameter combination's trackers
			hatchResults.push_back(checkSeasonSuccess(pf, pm, egg));	// Factorized season result
			hatchDays.push_back(egg.getIncubationDays());			    // Total number of days (maybe limit)
			totNeglect.push_back(egg.getTotNeg());						// Total neglect across season
			maxNeglect.push_back(egg.getMaxNeg());					    // Maximum neglect streak

			energy_F = pf.getEnergyRecord();							// Full energy record (female)
			endEnergy_F.push_back(energy_F[energy_F.size()-1]);			// Final energy value (female)
			meanEnergy_F.push_back(vectorMean(energy_F));				// Arithmetic mean energy across season (female)
			varEnergy_F.push_back(vectorVar(energy_F));					// Variance in energy across season (female)

			energy_M = pm.getEnergyRecord();							// Full energy record (male)
			endEnergy_M.push_back(energy_M[energy_M.size()-1]);			// Final energy value (male)
			meanEnergy_M.push_back(vectorMean(energy_M));				// Arith. mean energy across season (male)
			varEnergy_M.push_back(vectorVar(energy_M));					// Variance in enegy across season (male)

			std::vector<int> currIncubationBouts_F = pf.getIncubationBouts();	// Incubation bout lengths (female)
			std::vector<int> currForagingBouts_F = pf.getForagingBouts();		// Foraging bout lengths (female)

			std::vector<int> currIncubationBouts_M = pm.getIncubationBouts();	// Incubation bout lengths (male)
			std::vector<int> currForagingBouts_M = pm.getForagingBouts();		// Foraging bout lengths (male)

			meanIncubationBouts_F.push_back(vectorMean(currIncubationBouts_F));	// Arith. mean inc bout length (female)
			varIncubationBouts_F.push_back(vectorVar(currIncubationBouts_F));	// Variance in inc bout length (female)

			meanForagingBouts_F.push_back(vectorMean(currForagingBouts_F));		// Arith. mean foraging bout length (female)
			varForagingBouts_F.push_back(vectorVar(currForagingBouts_F));		// Variance in foraging bout length (female)

			meanIncubationBouts_M.push_back(vectorMean(currIncubationBouts_M)); // Arith. mean inc bout length (male)
			varIncubationBouts_M.push_back(vectorVar(currIncubationBouts_M));	// Variance in inc bout length (male)

			meanForagingBouts_M.push_back(vectorMean(currForagingBouts_M));		// Arith. mean foraging bout length (male)
			varForagingBouts_M.push_back(vectorVar(currForagingBouts_M));		// Variance in foraging bout length (male)
        }

        // Calculate Summary results across all iterations of parameter combos  		// All summarized across all iterations for these parameters
        int numSuccess                = isolateHatchResults(hatchResults, "success");		// # iteration successful hatch w/ living parents
        int numAllFail                = isolateHatchResults(hatchResults, "allFail");		// # iterations where parent(s) died and egg failed
        int numParentFail             = isolateHatchResults(hatchResults, "parentFail");	// # iterations parent(s) died
        int numEggTimeFail            = isolateHatchResults(hatchResults, "eggTimeFail");	// # iterations parents lived but egg failed from time limit
        int numEggColdFail            = isolateHatchResults(hatchResults, "eggColdFail");	// # iterations parents lived but egg failed from consecutive neglect
        double meanHatchDays          = vectorMean(hatchDays);					// Arith. mean egg age (across iterations)
        double meanTotNeglect         = vectorMean(totNeglect);					// Arith. total neglect across season 
        double meanMaxNeglect         = vectorMean(maxNeglect);					// Arith. mean maximum neglect streak 
        double meanEndEnergy_F        = vectorMean(endEnergy_F);				// Arith. mean final energy (female)
        double meanMeanEnergy_F       = vectorMean(meanEnergy_F);				// Arith. mean of mean energies (female)
        double meanVarEnergy_F        = vectorMean(varEnergy_F);				// Arith. mean of variance in energy (female)
        double meanEndEnergy_M        = vectorMean(endEnergy_M);				// Arith. mean of final energy (male)
        double meanMeanEnergy_M       = vectorMean(meanEnergy_M);				// Arith. mean of mean energies (male)
        double meanVarEnergy_M        = vectorMean(varEnergy_M);				// Arith. mean of variance in energy (male)
        double meanMeanIncBout_F      = vectorMean(meanIncubationBouts_F);			// Arith. mean of mean incubation bout length (female)
        double meanVarIncBout_F       = vectorMean(varIncubationBouts_F);			// Arith. mean of variance in incubation bout lengths (female)
        double meanMeanForagingBout_F = vectorMean(meanForagingBouts_F);			// Arith. mean of mean foraging bout length (female)
        double meanVarForagingBout_F  = vectorMean(varForagingBouts_F);				// Arith. mean of variance in foraging bout length (female)
        double meanMeanIncBout_M      = vectorMean(meanIncubationBouts_M);			// Arith. mean of mean incubation bout length (male)
        double meanVarIncBout_M       = vectorMean(varIncubationBouts_M);			// Arith. mean of variance in incubation bout length (mmale)
        double meanMeanForagingBout_M = vectorMean(meanForagingBouts_M);			// Arith. mean of mean foraging bout length (male)
        double meanVarForagingBout_M  = vectorMean(varForagingBouts_M);				// Arith. mean of variance in foraging bout length (male)

        // Write output in CSV formatted               	// All summarized across all iterations for these parameters
	outfile << iterations << ","			// Number of iterations for this parameter combo
		<< maxEnergyThresh << ","		// Max energy threshold (satiation) for both parents
		<< minEnergyThresh << ","		// Min energy threshold (hunger) for both parents
		<< foragingMean << ","			// Mean of foraging intake normal distribution for both parents
	    	<< numSuccess << ","			// # successful breeding iterations (egg hatched, both parents lived)
	    	<< numAllFail << ","			// # total failure iterations (egg died or failed to hatch, parent(s) died)
      		<< numParentFail << ","			// # parent death iterations (one or both parents)
		<< numEggTimeFail << ","		// # egg hatch fail iterations (reached time limit, too much total neglect)
		<< numEggColdFail << ","		// # egg cold fail iterations (too much consecutive neglect)
		<< meanHatchDays << ","			// Mean egg age when season ended 
		<< meanTotNeglect << ","		// Mean total neglect across the season
		<< meanMaxNeglect << ","		// Mean maximum neglect streak
		<< meanEndEnergy_F << ","		// Mean final energy (female)
		<< meanMeanEnergy_F << ","		// Mean of mean energy across season (female)
		<< meanVarEnergy_F << ","		// Mean of variance in energy across season (female)
		<< meanEndEnergy_M << ","		// Mean final energy (male)
		<< meanMeanEnergy_M << ","		// Mean of mean energy across season (male)
		<< meanVarEnergy_M << ","		// Mean of variance in energy across season (male)
		<< meanMeanIncBout_F << ","		// Mean of mean incubation bout length (female)
		<< meanVarIncBout_F << ","		// Mean of variance in incubation bout length (female) 
		<< meanMeanForagingBout_F << ","	// Mean of mean foraging bout length (female)
		<< meanVarForagingBout_F << ","		// Mean of variance in foraging bout length (male)
		<< meanMeanIncBout_M << ","		// Mean of mean incubation bout length (male)
		<< meanVarIncBout_M << ","		// Mean of variance in incubation bout length (male)
		<< meanMeanForagingBout_M << ","	// Mean of mean foraging bout length (male) 
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

	// Close file and exit
	outfile.close();
	std::cout << "Final output written to " << outfileName << "\n";
}

void breedingSeason(Parent& pf, Parent& pm, Egg& egg) 
{
	
	// The female pays the initial cost of the egg
	pf.setEnergy(pf.getEnergy() - egg.getEggCost());

	/* 
	main breeding season loop, which ticks forward in DAYS
	Breeding season lasts until the egg hatches succesfully, or 
 	if the egg hits the hard cut-off of incubation days due to 
 	accumulated neglect 
	*/
	while (!egg.isHatched() && 
		   (egg.getIncubationDays() <= egg.getMaxHatchDays())) {		

		// Check if eiter is incubating
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

		/*
		If both parents are now incubating before the start of the 
		next day, send the parent previously incubating away, while
		the newly arrived parent stays to incubate afresh
		*/
		if (pf.getState() == State::incubating &&
		    pm.getState() == State::incubating) {
			
			State previousFemaleState = pf.getPreviousDayState();
			State previousMaleState = pm.getPreviousDayState();

			// If the male has just returned, the female leaves
			if (previousFemaleState == State::incubating &&
			    previousMaleState == State::foraging) {
				pf.changeState();
				pf.setDidOverlap(true);

			// If the female has just returned, the male leaves
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

	pf.setEnergy(pf.getEnergy() - egg.getEggCost());

	while (!egg.isHatched() && 
	       (egg.getIncubationDays() <= egg.getMaxHatchDays())) {		

		bool incubated = false;
		if (pf.getState() == State::incubating ||
		    pm.getState() == State::incubating) {
			
			incubated = true;
		}

		egg.eggDay(incubated);

		pf.parentDay();
		pm.parentDay();

		/*
		Unlike the standard breedingSeason, this model has random overlap switches
		If both parents are now incubating before
		the start of the nexy day, a random parent is sent to forage
		*/
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