#include <iostream>
#include <fstream>

#include <string>
#include <vector>
#include "Rcpp.h"

#include "Egg.hpp"
#include "Parent.hpp"

constexpr static int ITERATIONS = 100000;

void breedingSeason(Parent&, Parent&, Egg&);

// [[Rcpp::export]]
int main()
{
	// initialize output results objects
	std::vector<bool> hatchSuccess = std::vector<bool>();
	std::vector<double> hatchDays = std::vector<double>();
	std::vector<int> maxNeglect = std::vector<int>();

	std::vector<std::vector<double> > energy_M = std::vector<std::vector<double> >();
	std::vector<std::vector<int> > incubationBouts_M = std::vector<std::vector<int> >();
	std::vector<std::vector<int> > foragingBouts_M = std::vector<std::vector<int> >();

	std::vector<std::vector<double> > energy_F = std::vector<std::vector<double> >();
	std::vector<std::vector<int> > incubationBouts_F = std::vector<std::vector<int> >();
	std::vector<std::vector<int> > foragingBouts_F = std::vector<std::vector<int> >();

	for (int i = 0; i < ITERATIONS; i++) {
		// initialize individuals for this simulation iteration
		Parent pm = Parent(Sex::male);
		Parent pf = Parent(Sex::female);
		Egg egg = Egg();

		// run breeding season
		breedingSeason(pm, pf, egg);

		Rcpp::Rcout << egg.isHatched();

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

	std::ofstream test;
	test.open("Output/test.txt");

	test << "iteration,hatchSuccess,hatchDays,maxNeglect,energy_M,energy_F\n";
	for (int i = 0; i < ITERATIONS; i++) {
		test << i << ",";
		test << hatchSuccess[i] << ",";
		test << hatchDays[i] << ",";
		test << maxNeglect[i] << ",";
		test << energy_M[i][energy_M[i].size()-1] << ",";
		test << energy_F[i][energy_F[i].size()-1] << "\n";
	}

	return 0;
}

void breedingSeason(Parent& pm, Parent& pf, Egg& egg) {
	
	while (!egg.isHatched() && (egg.getIncubationDays() <= Egg::HATCH_DAYS_MAX)) {		
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