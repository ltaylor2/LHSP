#include "Egg.hpp"

Egg::Egg():
	alive(true),
	hatched(false),
	currDays(0),
	hatchDays(START_HATCH_DAYS),
	currNegCounter(0),
	totNegCounter(0),
	maxNegCounter(0)
{}

void Egg::eggDay(bool incubated)
{

	// Incubation resets the neglect counter
	if (incubated) {
		this->currNegCounter = 0;
	} 

	// Keeping track of egg neglect
	else {
		currNegCounter++;
		totNegCounter++;
		if (currNegCounter > maxNegCounter) {
			this->maxNegCounter = currNegCounter;
		}
	}

	// Incubation finishes when it reaches the incubation limit
	// (Here not effected by neglect within the simulations itself)
	if (currDays >= hatchDays) {
		this->hatched = true;
	}

	currDays++;
}