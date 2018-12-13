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

	// Neglected eggs suffer an incubation penalty
	else {
		currNegCounter++;
		totNegCounter++;
		if (currNegCounter > maxNegCounter) {
			this->maxNegCounter = currNegCounter;
		}

		hatchDays += NEGLECT_PENALTY;
	}

	// Egg hatches when it catches up with the required hatching time
	if (currDays >= hatchDays) {
		this->hatched = true;
	}

	currDays++;
}