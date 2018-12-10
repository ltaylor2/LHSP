#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <random>
#include <chrono>
#include "Rcpp.h"

#include <unistd.h>

#include "Util.hpp"
#include "Egg.hpp"
#include "Parent.hpp"

constexpr static int ITERATIONS = 10000;

constexpr static double SEXDIFF_COEFFS[10] = {0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9};
constexpr static double FORAGINGDIFF_COEFFS[10] = {1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7, 1.8, 1.9, 2.0};

constexpr static char NULL_FNAME[] = "null_output.txt";
constexpr static char OVERLAP_FNAME[] = "overlap_output.txt";
constexpr static char OVERLAPRAND_FNAME[] = "overlaprand_output.txt";
constexpr static char SEXDIFF_FNAME[] = "sexdiff_output.txt";
constexpr static char SEXDIFFCOMP_1_FNAME[] = "sexdiffcomp_1_output.txt";
constexpr static char SEXDIFFCOMP_2_FNAME[] = "sexdiffcomp_2_output.txt";
constexpr static char FORAGINGDIFF_FNAME[] = "foragingdiff_output.txt";

static std::mt19937* randGen;

void breedingSeason_NULL(Parent&, Parent&, Egg&, int);
void breedingSeason_OVERLAP(Parent&, Parent&, Egg&, int);
void breedingSeason_OVERLAPRAND(Parent&, Parent&, Egg&, int);
void breedingSeason_SEXDIFF(Parent&, Parent&, Egg&, int);
void breedingSeason_SEXDIFFCOMP_1(Parent&, Parent&, Egg&, int);
void breedingSeason_SEXDIFFCOMP_2(Parent&, Parent&, Egg&, int);
void breedingSeason_FORAGINGDIFF(Parent&, Parent&, Egg&, int);

void runModel(int, void(*)(Parent&, Parent&, Egg&, int), std::string);

// [[Rcpp::export]]
int main()
{
	auto startTime = std::chrono::system_clock::now();

	// seed original random generator to pass to all Parent instances
	auto seed = std::chrono::high_resolution_clock::now().time_since_epoch().count();
	std::mt19937 r = std::mt19937(seed);
	randGen = &r;

	Rcpp::Rcout << "\n\n\n" << "Beginning model runs" << "\n\n\n";

	runModel(ITERATIONS, *breedingSeason_NULL, NULL_FNAME);
	runModel(ITERATIONS, *breedingSeason_OVERLAP, OVERLAP_FNAME);
	runModel(ITERATIONS, *breedingSeason_OVERLAPRAND, OVERLAPRAND_FNAME);
	runModel(ITERATIONS*10, *breedingSeason_SEXDIFF, SEXDIFF_FNAME);
	runModel(ITERATIONS*10, *breedingSeason_SEXDIFFCOMP_1, SEXDIFFCOMP_1_FNAME);
	runModel(ITERATIONS*10, *breedingSeason_SEXDIFFCOMP_2, SEXDIFFCOMP_2_FNAME);
	runModel(ITERATIONS*10, *breedingSeason_FORAGINGDIFF, FORAGINGDIFF_FNAME);

	auto endTime = std::chrono::system_clock::now();

	std::chrono::duration<double> runTime = endTime - startTime;

	Rcpp::Rcout << "All model output written" << "\n"
				<< "Runtime in "
				<< runTime.count() << " s."
				<< "\n";
	return 0;
}

void runModel(int iterations, 
			  void (*modelFunc)(Parent&, Parent&, Egg&, int iter), 
			  std::string outfileName) 
{


	std::ofstream outfile;
	outfile.open("Output/" + outfileName, std::ofstream::trunc);

	outfile << "iteration,hatchSuccess,hatchDays,maxNeglect,"
			<< "endEnergy_M,meanEnergy_M,varEnergy_M,"
			<< "endEnergy_F,meanEnergy_F,varEnergy_F,"
			<< "meanIncubation_M,varIncubation_M,numIncubation_M,"
			<< "meanForaging_M,varForaging_M,numForaging_M,"
			<< "meanIncubation_F,varIncubation_F,numIncubation_F,"
			<< "meanForaging_F,varForaging_F,numForaging_F"
		    << "\n";

	// initialize output results objects
	std::vector<bool> hatchSuccess = std::vector<bool>();
	std::vector<double> hatchDays = std::vector<double>();
	std::vector<int> maxNeglect = std::vector<int>();

	std::vector<double> energy_M = std::vector<double>();

	std::vector<double> energy_F = std::vector<double>();

	std::vector<int> incubationBouts_M = std::vector<int>();
	std::vector<int> foragingBouts_M = std::vector<int>();
	std::vector<int> incubationBouts_F = std::vector<int>();
	std::vector<int> foragingBouts_F = std::vector<int>();

	for (int i = 0; i < iterations; i++) {

		if (iterations >= 10 && i % (iterations/10) == 0) {
				Rcpp::Rcout << "LHSP Model for " + outfileName + " on Iteration: " 
							<< i << "\n";
		}

		// initialize individuals for this simulation iteration
		Parent pm = Parent(Sex::male, randGen);
		Parent pf = Parent(Sex::female, randGen);
		Egg egg = Egg();

		// run breeding season
		modelFunc(pm, pf, egg, i);

		// save results
		hatchSuccess.push_back(egg.isHatched());
		hatchDays.push_back(egg.getIncubationDays());
		maxNeglect.push_back(egg.getMaxNeg());

		energy_M = pm.getEnergyRecord();
		energy_F = pf.getEnergyRecord();

		incubationBouts_M = pm.getIncubationBouts();
		foragingBouts_M = pm.getForagingBouts();
		incubationBouts_F = pf.getIncubationBouts();
		foragingBouts_F = pf.getForagingBouts();

		double endEnergy_M = energy_M[energy_M.size()-1];
		double meanEnergy_M = vectorMean(energy_M);
		double varEnergy_M = vectorVar(energy_M);

		double endEnergy_F = energy_F[energy_F.size()-1];
		double meanEnergy_F = vectorMean(energy_F);
		double varEnergy_F = vectorVar(energy_F);

		double meanIncubation_M = vectorMean(incubationBouts_M);
		double varIncubation_M = vectorVar(incubationBouts_M);
		double numIncubation_M = incubationBouts_M.size();

		double meanForaging_M = vectorMean(foragingBouts_M);
		double varForaging_M = vectorVar(foragingBouts_M);
		double numForaging_M = foragingBouts_M.size();

		double meanIncubation_F = vectorMean(incubationBouts_F);
		double varIncubation_F = vectorVar(incubationBouts_F);
		double numIncubation_F = incubationBouts_F.size();

		double meanForaging_F = vectorMean(foragingBouts_F);
		double varForaging_F = vectorVar(foragingBouts_F);
		double numForaging_F = foragingBouts_F.size();

		outfile << i << ","
		        << hatchSuccess[i] << ","
			    << hatchDays[i] << ","
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

	outfile.close();
	Rcpp::Rcout << "Final output written to " << outfileName << "\n\n";
}

void breedingSeason_NULL(Parent& pm, Parent& pf, Egg& egg, int iter) {
	
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

void breedingSeason_OVERLAP(Parent& pm, Parent& pf, Egg& egg, int iter) {
	
	while (!egg.isHatched() && 
		   (egg.getIncubationDays() <= Egg::HATCH_DAYS_MAX)) {		
		pm.parentDay();
		pf.parentDay();

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

				// allow the previously incubating bird to forage
				if (previousMaleState == State::incubating) {
					pm.changeState();
				} else if (previousFemaleState == State::incubating) {
					pf.changeState();
				}
			}
		}
		egg.eggDay(incubated);
	}
}

void breedingSeason_OVERLAPRAND(Parent& pm, Parent& pf, Egg& egg, int iter) {
	while (!egg.isHatched() && 
	   (egg.getIncubationDays() <= Egg::HATCH_DAYS_MAX)) {		
		pm.parentDay();
		pf.parentDay();

		bool incubated = false;
		if (pm.getState() == State::incubating ||
			pf.getState() == State::incubating) {
			incubated = true;

			// in this model, we don't allow both parents to incubate.
			// rather than optimally switching based on who's been there longer, we switch randomly
			if (pm.getState() == State::incubating &&
				pf.getState() == State::incubating) {

				if ((double)rand() / RAND_MAX <= 0.5) {
					pm.changeState();
				} else {
					pf.changeState();
				}
			}
		}
		egg.eggDay(incubated);
	}
}

void breedingSeason_SEXDIFF(Parent& pm, Parent& pf, Egg& egg, int iter) {
	// Calculate energy coefficient using the 10x iteration %
	double sexdiffCoeff = SEXDIFF_COEFFS[iter % 10];

	// Female pays initial cost of egg at the beginning of each breeding season.
	pf.setEnergy(pf.getEnergy() * sexdiffCoeff);

	breedingSeason_OVERLAP(pm, pf, egg, iter);
}

void breedingSeason_SEXDIFFCOMP_1(Parent& pm, Parent& pf, Egg& egg, int iter) {
	double sexdiffCoeff = SEXDIFF_COEFFS[iter % 10];

	pf.setEnergy(pf.getEnergy() * sexdiffCoeff);

	// in addition to sex differences, see if male behavior can compensate by lowering return energy threshold
	// (i.e., more selfless males)
	while (!egg.isHatched() && 
	   (egg.getIncubationDays() <= Egg::HATCH_DAYS_MAX)) {		
		pm.parentDay();
		pf.parentDay();

		bool incubated = false;
		if (pm.getState() == State::incubating ||
			pf.getState() == State::incubating) {
			incubated = true;

			// in this model, we don't allow both parents to incubate.
			// rather than optimally switching based on who's been there longer, we switch randomly
			if (pm.getState() == State::incubating &&
				pf.getState() == State::incubating) {

				if ((double)rand() / RAND_MAX <= (2.0/3)) {
					pm.changeState();
				} else {
					pf.changeState();
				}
			}
		}
		egg.eggDay(incubated);
	}
}

void breedingSeason_SEXDIFFCOMP_2(Parent& pm, Parent& pf, Egg& egg, int iter) {
	// in addition to sex differences, see if male behavior can compensate by lowering return energy threshold
	// (i.e., more selfless males)
	pm.setReturnEnergyThreshold(pm.getReturnEnergyThreshold()*0.5);

	breedingSeason_SEXDIFF(pm, pf, egg, iter);
}

void breedingSeason_FORAGINGDIFF(Parent& pm, Parent&pf, Egg& egg, int iter) {
	double foragingdiffCoeff = FORAGINGDIFF_COEFFS[iter % 10];

	pm.setForagingDistribution(Parent::FORAGING_MEAN, Parent::FORAGING_SD * foragingdiffCoeff);
	pf.setForagingDistribution(Parent::FORAGING_MEAN, Parent::FORAGING_SD * foragingdiffCoeff);

	breedingSeason_OVERLAP(pm, pf, egg, iter);
}