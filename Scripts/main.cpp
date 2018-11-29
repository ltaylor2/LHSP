#include <iostream>
#include <vector>
#include <ctime>
#include "Rcpp.h"

#include "Egg.hpp"
#include "Parent.hpp"

constexpr static int ITERATIONS = 100000;

void breedingSeason(Parent&, Parent&, Egg&);

// [[Rcpp::export]]"
int main(int argc, char* argv[])
{
	srand(time(NULL));

	// initialize output results objects
	std::vector<bool> hatchSuccess = std::vector<bool>();
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

		// save results
		hatchSuccess.push_back(egg.isHatched());
		maxNeglect.push_back(egg.getMaxNeg());

		energy_M.push_back(pm.getEnergyRecord());
		incubationBouts_M.push_back(pm.getIncubationBouts());
		foragingBouts_M.push_back(pm.getForagingBouts());

		energy_F.push_back(pf.getEnergyRecord());
		incubationBouts_F.push_back(pf.getIncubationBouts());
		foragingBouts_F.push_back(pf.getForagingBouts());
	}
}

void breedingSeason(Parent& pm, Parent& pf, Egg& egg) {
	
	while (!egg.isHatched() && egg.getIncubationDays() <= Egg::HATCH_DAYS_MAX) {
		pm.parentDay();
		pf.parentDay();

		bool incubated = false;
		if (pm.getState() == State::incubating ||
			pf.getState() == State::incubating) {
			incubated = true;
		}
		egg.eggDay(incubated);
	}
}