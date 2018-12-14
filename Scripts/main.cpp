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
constexpr static int ITERATIONS = 100;

// Multiplicative coefficients of egg cost (i.e., 1, 2, 3, eggs laid as cost)
constexpr static double SEXDIFF_COEFFS[5] = {1, 2, 3, 4, 5};

// Multiplicative coefficents for variance of foraging dist. (+variance) 
constexpr static double FORAGINGVAR_COEFFS[10] = {1.1, 1.2, 1.3, 1.4, 1.5, 
												  1.6, 1.7, 1.8, 1.9, 2.0};

// Multiplicative coefficients for mean of foraging dist (-mean)
constexpr static double FORAGINGMEAN_COEFFS[10] = {0.80, 0.82, 0.84, 0.86, 0.88,
												   0.90, 0.92, 0.94, 0.96, 0.98};

// All output in from the model is written directly to file
constexpr static char NULL_FNAME[]         = "null_output.txt";
constexpr static char OVERLAP_SWAP_FNAME[] = "overlap_swap_output.txt";
constexpr static char OVERLAP_RAND_FNAME[] = "overlap_rand_output.txt";
constexpr static char SEXDIFF_FNAME[] 	   = "sexdiff_output.txt";
constexpr static char FORAGINGVAR_FNAME[]  = "foragingvar_output.txt";
constexpr static char FORAGINGMEAN_FNAME[] = "foragingmean_output.txt";

// constexpr static char SEXDIFFCOMP_1_FNAME[] = "sexdiffcomp_1_output.txt";
// constexpr static char SEXDIFFCOMP_2_FNAME[] = "sexdiffcomp_2_output.txt";

// Need a single, static random generator device to let us only seed once
static std::mt19937* randGen;

// Prototypes -- see functions for documentation
void breedingSeason_NULL(Parent&, Parent&, Egg&, int);
void breedingSeason_OVERLAP_SWAP(Parent&, Parent&, Egg&, int);
void breedingSeason_OVERLAP_RAND(Parent&, Parent&, Egg&, int);
void breedingSeason_SEXDIFF(Parent&, Parent&, Egg&, int);
void breedingSeason_FORAGINGVAR(Parent&, Parent&, Egg&, int);
void breedingSeason_FORAGINGMEAN(Parent&, Parent&, Egg&, int);
void runModel(int, void(*)(Parent&, Parent&, Egg&, int), std::string);

// Sex-specific difference compensation. Not in current build.

// void breedingSeason_SEXDIFFCOMP_1(Parent&, Parent&, Egg&, int);
// void breedingSeason_SEXDIFFCOMP_2(Parent&, Parent&, Egg&, int);

// [[Rcpp::export]]
int main()
{
	// Record model timing to help me know which computer is the fanciest
	auto startTime = std::chrono::system_clock::now();

	// Seed static random generator device with ridiculous C++11 things
	auto seed = 
		std::chrono::high_resolution_clock::now().time_since_epoch().count();
	std::mt19937 r = std::mt19937(seed);
	randGen = &r;

	// All output to R terminals has to be with Rcout
	Rcpp::Rcout << "\n\n\n" << "Beginning model runs" << "\n\n\n";

	/*
		Call each model by passing model info (including the *function itself),
		to the runModel function, which runs the model and writes output to 
		file. Models with parameter coefficient sets are multiplied by the number
		of coefficients, so all sets run for ITERATIONS iteration.
	*/  
	runModel(ITERATIONS, *breedingSeason_NULL, NULL_FNAME);
	runModel(ITERATIONS, *breedingSeason_OVERLAP_SWAP, OVERLAP_SWAP_FNAME);
	runModel(ITERATIONS, *breedingSeason_OVERLAP_RAND, OVERLAP_RAND_FNAME);

	runModel(ITERATIONS*5, *breedingSeason_SEXDIFF, SEXDIFF_FNAME);
	runModel(ITERATIONS*10, *breedingSeason_FORAGINGVAR, FORAGINGVAR_FNAME);
	runModel(ITERATIONS*10, *breedingSeason_FORAGINGMEAN, FORAGINGMEAN_FNAME);

	// runModel(ITERATIONS, *breedingSeason_SEXDIFFCOMP_1, SEXDIFFCOMP_1_FNAME);
	// runModel(ITERATIONS, *breedingSeason_SEXDIFFCOMP_2, SEXDIFFCOMP_2_FNAME);

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
			<< "meanForaging_F,varForaging_F,numForaging_F"
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

		// Save results of each season
		hatchSuccess.push_back(egg.isHatched());	   // successful season?
		hatchDays.push_back(egg.getIncubationDays());  // number of days to hatch

		totNeglect.push_back(egg.getTotNeg());		   // total neglect
		maxNeglect.push_back(egg.getMaxNeg());		   // max neglect streak

		energy_M = pm.getEnergyRecord();			   // full season energy M
		energy_F = pf.getEnergyRecord();			   // full season energy F

		incubationBouts_M = pm.getIncubationBouts();   // inc. bout record M
		foragingBouts_M = pm.getForagingBouts();	   // forgaging bout record M
		incubationBouts_F = pf.getIncubationBouts();   // inc. bout record F
		foragingBouts_F = pf.getForagingBouts();	   // foraging bout record F

		double endEnergy_M = energy_M[energy_M.size()-1];	// energy at end of season M
		double meanEnergy_M = vectorMean(energy_M);			// mean energy across season M
		double varEnergy_M = vectorVar(energy_M);			// variance in energy across season M

		double endEnergy_F = energy_F[energy_F.size()-1];	// energy at end of season F
		double meanEnergy_F = vectorMean(energy_F);			// mean energy across season F
		double varEnergy_F = vectorVar(energy_F);			// variance in energy across season F

		double meanIncubation_M = vectorMean(incubationBouts_M);	// mean inc. bout length M
		double varIncubation_M = vectorVar(incubationBouts_M);		// variance in inc. bout length M
		double numIncubation_M = incubationBouts_M.size();			// number of inc. bouts M

		double meanForaging_M = vectorMean(foragingBouts_M);		// mean foraging bout length M
		double varForaging_M = vectorVar(foragingBouts_M);			// variance in foraging bout length M
		double numForaging_M = foragingBouts_M.size();				// number of foraging bouts M

		double meanIncubation_F = vectorMean(incubationBouts_F);	// mean inc. bout length F
		double varIncubation_F = vectorVar(incubationBouts_F);		// variance in inc. bout length F
		double numIncubation_F = incubationBouts_F.size();			// number of inc. bouts F

		double meanForaging_F = vectorMean(foragingBouts_F);		// mean foraging bout lenght F
		double varForaging_F = vectorVar(foragingBouts_F);			// variance in foraging bout length F
		double numForaging_F = foragingBouts_F.size();				// number of foraging bouts F

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
			    << numForaging_F << "\n";
	}

	// Close file and exit
	outfile.close();
	Rcpp::Rcout << "Final output written to " << outfileName << "\n\n";
}

/*
	NULL model breeding season
	@param pm male adult parent
		   pf female adult parent
		   egg and egg, if it was unclear
		   iter current iteration of breeding season 

	In the NULL model, parents lose energy while incubating and gain/lose
	energy while foraging, with no addition additional state rules.
*/
void breedingSeason_NULL(Parent& pm, Parent& pf, Egg& egg, int iter) {
	/* 
		Breeding season lasts until the egg hatches succesfully, or 
	 	if the egg hits the hard cut-off of incubation days due to 
	 	accumulated neglect 
	*/
	while (!egg.isHatched() && 
		   (egg.getIncubationDays() <= Egg::HATCH_DAYS_MAX)) {		

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
	}
}

/*
	OVERLAP_SWAP model breeding season
	@param pm male adult parent
		   pf female adult parent
		   egg and egg, if it was unclear
		   iter current iteration of breeding season 

	In the OVERLAP_SWAP model, all NULL model behavior is retained, with 
	an additional rule that prevents redundant incubating by two parents.
	After all egg + parent behavior occurs for the given day, the model checks
	if both parents are incubating. If so, the one that was incubating on the
	previous day switches to foraging, regardless of normal energetic
	thresholding.
*/
void breedingSeason_OVERLAP_SWAP(Parent& pm, Parent& pf, Egg& egg, int iter) {
	/* 
		Breeding season lasts until the egg hatches succesfully, or 
	 	if the egg hits the hard cut-off of incubation days due to 
	 	accumulated neglect 
	*/
	while (!egg.isHatched() && 
		   (egg.getIncubationDays() <= Egg::HATCH_DAYS_MAX)) {		

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

/*
	OVERLAP_RAND model breeding season
	@param pm male adult parent
		   pf female adult parent
		   egg and egg, if it was unclear
		   iter current iteration of breeding season 

	The OVERLAP_RAND model is identical to the OVERLAP_SWAP model, except that
	when both adults are incubating before the beginning of the next day,
	the parent that swaps back to foraging is always chosen randomly (rather than
	the parent that was previously incubating).
*/
void breedingSeason_OVERLAP_RAND(Parent& pm, Parent& pf, Egg& egg, int iter) {
	
	while (!egg.isHatched() && 
		   (egg.getIncubationDays() <= Egg::HATCH_DAYS_MAX)) {		

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
		// next day, send a random parent back to foraging
		if (pm.getState() == State::incubating &&
			pf.getState() == State::incubating) {
					
			if ((double)rand() / RAND_MAX <= 0.5) {
				pm.changeState();
			} else {
				pf.changeState();
			}
		}
	}
}

/*
	SEXDIFF model breeding season
	@param pm male adult parent
		   pf female adult parent
		   egg and egg, if it was unclear
		   iter current iteration of breeding season 

	The SEXDIFF model inherits all the behavior of the OVERLAP_SWAP model,
	with a single energetic penalty to the female to represent the cost of 
	the egg. 

	This model iterates through the coefficients defined in SEXDIFF_COEFFS,
	which represent multiplying the cost of an egg by 1x-5x, simulating
	a greater single energetic cost for larger clutch sizes.
*/
void breedingSeason_SEXDIFF(Parent& pm, Parent& pf, Egg& egg, int iter) {

	/*
		Easily step through parameter set arrays using mods
		(i.e., every 4th iteration will run the 4th parameter from the array)
		This model is sent 5x the iterations, so all sets are 
		equally represented
	*/
	double sexdiffCoeff = SEXDIFF_COEFFS[iter%5];

	// Female pays initial cost of egg(s) before season begins
	pf.setEnergy(pf.getEnergy() - Egg::EGG_COST * sexdiffCoeff);

	// Then begin all behavior from OVERLAP_SWAP
	breedingSeason_OVERLAP_SWAP(pm, pf, egg, iter);
}

/*
	FORAGINGVAR model breeding season
	@param pm male adult parent
		   pf female adult parent
		   egg and egg, if it was unclear
		   iter current iteration of breeding season 

	The FORAGINGVAR model inherits all the behavior of the SEXDIFF model
	(with a single egg cost), with additional parameter settings that steps
	through increases to the standard deviation of the normal distribution
	that defines foraging outcomes. 
*/
void breedingSeason_FORAGINGVAR(Parent& pm, Parent&pf, Egg& egg, int iter) {

	// Again relying on mod math to easily step through parameters
	double foragingdiffCoeff = FORAGINGVAR_COEFFS[iter % 10];

	// Both parents get a new foraging distribution SD for the season
	pm.setForagingDistribution(Parent::FORAGING_MEAN, 
							   Parent::FORAGING_SD * foragingdiffCoeff);
	pf.setForagingDistribution(Parent::FORAGING_MEAN, 
							   Parent::FORAGING_SD * foragingdiffCoeff);

	// Female incurs one-time cost of individual egg
	pf.setEnergy(pf.getEnergy() - Egg::EGG_COST);

	// Then begin all behavior from OVERLAP_SWAP
	breedingSeason_OVERLAP_SWAP(pm, pf, egg, iter);
}

/*
	FORAGINGMEAN model breeding season
	@param pm male adult parent
		   pf female adult parent
		   egg and egg, if it was unclear
		   iter current iteration of breeding season 

	The FORAGINGMEAN model inherits all the behavior of the SEXDIFF model
	(with a single egg cost), with additional parameter settings that steps
	through decreases to the mean of the normal distribution
	that defines foraging outcomes. 
*/
void breedingSeason_FORAGINGMEAN(Parent& pm, Parent&pf, Egg& egg, int iter) {

	// Mod math, again
	double foragingdiffCoeff = FORAGINGMEAN_COEFFS[iter % 10];

	// Both parents get a new foraging distribution mean for the season
	pm.setForagingDistribution(Parent::FORAGING_MEAN * foragingdiffCoeff, 
							   Parent::FORAGING_SD);
	pf.setForagingDistribution(Parent::FORAGING_MEAN * foragingdiffCoeff, 
							   Parent::FORAGING_SD);

	// Inhereit SEXDIFF cost, but with only egg
	pf.setEnergy(pf.getEnergy() - Egg::EGG_COST);

	// Then begin all behavior from OVERLAP_SWAP
	breedingSeason_OVERLAP_SWAP(pm, pf, egg, iter);
}

/*
	SEXDIFFCOMP_1 model breeding season -- NOT USED IN THIS BUILD
	@param pm male adult parent
		   pf female adult parent
		   egg and egg, if it was unclear
		   iter current iteration of breeding season 

	The SEXDIFFCOMP_1 model inherits all the behavior of the SEXDIFF model,
	with altered male behavior as a possible compensating mechanism. Here,
	rather than the more orderly switching of the OVERLAP_SWAP model, the male
	is always twice as likely as the female to remain incubating if there is an
	incubation overlap, freeing the female to forage.
*/
// void breedingSeason_SEXDIFFCOMP_1(Parent& pm, Parent& pf, Egg& egg, int iter) {

// 	// Inhereit SEXDIFF cost, but with only egg
// 	pf.setEnergy(pf.getEnergy() - Egg::EGG_COST);
	
// 	while (!egg.isHatched() && 
// 		   (egg.getIncubationDays() <= Egg::HATCH_DAYS_MAX)) {		

// 		// Check if parent is incubating
// 		bool incubated = false;
// 		if (pm.getState() == State::incubating ||
// 			pf.getState() == State::incubating) {
			
// 			incubated = true;
// 		}

// 		// Egg behavior based on incubation
// 		egg.eggDay(incubated);

// 		// Parent behavior, including state change
// 		pm.parentDay();
// 		pf.parentDay();

// 		// If both parents are now incubating before the start of the 
// 		// Male has 2/3 chance of being the one to remain incubating,
// 		// While the female forages
// 		if (pm.getState() == State::incubating &&
// 			pf.getState() == State::incubating) {

// 			if ((double)rand() / RAND_MAX <= (1.0/3)) {
// 				pm.changeState();
// 			} else {
// 				pf.changeState();
// 			}
// 		}
// 	}
// }

/*
	SEXDIFFCOMP_2 model breeding season -- NOT USED IN THIS BUILD
	@param pm male adult parent
		   pf female adult parent
		   egg and egg, if it was unclear
		   iter current iteration of breeding season 

	The SEXDIFFCOMP_2 model inherits all the behavior of the SEXDIFF model,
	with altered male behavior as a possible compensating mechanism. Here,
	the compensating mechanism is a relaxed physiological sensitivity on the 
	part of the male. Males have half the required maximum energy threshold
	in returning from foraging.
*/
// void breedingSeason_SEXDIFFCOMP_2(Parent& pm, Parent& pf, Egg& egg, int iter) {
	
// 	// Male's maximum energy threshold to return from foraging is halved
// 	pm.setReturnEnergyThreshold(pm.getReturnEnergyThreshold()*0.5);

// 	// Inhereit SEXDIFF cost, but with only egg
// 	pf.setEnergy(pf.getEnergy() - Egg::EGG_COST);

// 	// Then begin all behavior from OVERLAP_SWAP
// 	breedingSeason_OVERLAP_SWAP(pm, pf, egg, iter);
// }
