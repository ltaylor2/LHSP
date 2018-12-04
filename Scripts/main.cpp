#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <chrono>

#include "Rcpp.h"

#include "Egg.hpp"
#include "Parent.hpp"

constexpr static int ITERATIONS = 100000;
constexpr static char NULL_FNAME[] = "null_output.txt";
constexpr static char OVERLAP_FNAME[] = "overlap_output.txt";

void breedingSeason_NULL(Parent&, Parent&, Egg&);
void breedingSeason_OVERLAP(Parent&, Parent&, Egg&);

void runModel(int, void(*)(Parent&, Parent&, Egg&), std::string);

// [[Rcpp::export]]
int main()
{
	auto startTime = std::chrono::system_clock::now();

	Rcpp::Rcout << "\n\n\n" << "Beginning model runs" << "\n\n\n";

	runModel(ITERATIONS, *breedingSeason_NULL, NULL_FNAME);
	runModel(ITERATIONS, *breedingSeason_OVERLAP, OVERLAP_FNAME);
	
	auto endTime = std::chrono::system_clock::now();

	std::chrono::duration<double> runTime = endTime - startTime;

	Rcpp::Rcout << "All model output written" << "\n"
				<< "Runtime in "
				<< runTime.count() << " s."
				<< "\n";
	return 0;
}

void runModel(int iterations, 
			  void (*modelFunc)(Parent&, Parent&, Egg&), 
			  std::string outfileName) {
	// initialize output results objects
	std::vector<bool> hatchSuccess = std::vector<bool>();
	std::vector<double> hatchDays = std::vector<double>();
	std::vector<int> maxNeglect = std::vector<int>();

	std::vector<std::vector<double> > energy_M = 
									  std::vector<std::vector<double> >();
	std::vector<std::vector<int> > incubationBouts_M = 
								   std::vector<std::vector<int> >();
	std::vector<std::vector<int> > foragingBouts_M = 
								   std::vector<std::vector<int> >();

	std::vector<std::vector<double> > energy_F = 
									  std::vector<std::vector<double> >();
	std::vector<std::vector<int> > incubationBouts_F = 
								   std::vector<std::vector<int> >();
	std::vector<std::vector<int> > foragingBouts_F = 
								   std::vector<std::vector<int> >();

	for (int i = 0; i < iterations; i++) {

		if (iterations >= 10) {
			if (i % (iterations/10) == 0) {
				Rcpp::Rcout << "LHSP Model for " + outfileName + " on Iteration: " 
							<< i << "\n";
			}
		}

		// initialize individuals for this simulation iteration
		Parent pm = Parent(Sex::male);
		Parent pf = Parent(Sex::female);
		Egg egg = Egg();

		// run breeding season
		modelFunc(pm, pf, egg);

		// save results
		hatchSuccess.push_back(egg.isHatched());
		hatchDays.push_back(egg.getIncubationDays());
		maxNeglect.push_back(egg.getMaxNeg());

		energy_M.push_back(pm.getEnergyRecord());
		incubationBouts_M.push_back(pm.getIncubationBouts());
		foragingBouts_M.push_back(pm.getForagingBouts());

		energy_F.push_back(pf.getEnergyRecord());
		incubationBouts_F.push_back(pf.getIncubationBouts());
		foragingBouts_F.push_back(pf.getForagingBouts());
	}

	std::ofstream outfile;
	outfile.open("Output/" + outfileName, std::ofstream::trunc);

	outfile << "iteration,hatchSuccess,hatchDays,maxNeglect,energy_M,energy_F"
		    << "\n";

	for (int i = 0; i < iterations; i++) {
		outfile << i << ","
		        << hatchSuccess[i] << ","
			    << hatchDays[i] << ","
			    << maxNeglect[i] << ","
			    << energy_M[i][energy_M[i].size()-1] << ","
			    << energy_F[i][energy_F[i].size()-1] << "\n";
	}

	Rcpp::Rcout << "Final output written to " << outfileName << "\n\n";
}

void breedingSeason_NULL(Parent& pm, Parent& pf, Egg& egg) {
	
	while (!egg.isHatched() && 
		   (egg.getIncubationDays() <= Egg::HATCH_DAYS_MAX)) {		
		pm.parentDay();
		pf.parentDay();

		// Rcpp::Rcout << pm.getEnergy() << "////" << pf.getEnergy() << "\n";
		bool incubated = false;
		if (pm.getState() == State::incubating ||
			pf.getState() == State::incubating) {
			incubated = true;
		}
		egg.eggDay(incubated);
	}
}

void breedingSeason_OVERLAP(Parent& pm, Parent& pf, Egg& egg) {
	
	while (!egg.isHatched() && 
		   (egg.getIncubationDays() <= Egg::HATCH_DAYS_MAX)) {		
		pm.parentDay();
		pf.parentDay();

		// Rcpp::Rcout << egg.getIncubationDays()
		// 			<< "  ///  "
		// 			<< pm.getStrState()
		// 			<< "_"
		// 			<< pm.getEnergy()
		// 			<< " // "
		// 		    << pf.getStrState() 
		// 		    << "_"
		// 		    << pf.getEnergy()
		// 		    << "\n";

		bool incubated = false;
		if (pm.getState() == State::incubating ||
			pf.getState() == State::incubating) {
			incubated = true;

			// in this model, we don't allow both parents to incubate.
			// if both parents are incubating, we send the one that has
			// been incubating longer away.
			if (pm.getState() == State::incubating &&
				pf.getState() == State::incubating) {
				State previousMaleState = pm.getPreviousDayState();
				State previousFemaleState = pf.getPreviousDayState();

				// Rcpp::Rcout << "SWITCHING FROM OVERLAP" << "\n";

				// if the male was previously incubating, allow him to forage
				if (previousMaleState == State::incubating) {
					pm.setState(State::foraging);
				} else if (previousFemaleState == State::incubating) {
					pf.setState(State::foraging);
				}
			}
		}
		egg.eggDay(incubated);
	}
}