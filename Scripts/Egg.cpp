#include "Egg.hpp"

Egg::Egg():
	alive(true),
	hatched(false),
	eggCost(EGG_COST),
	currDays(0),
	hatchDays(START_HATCH_DAYS),
	maxHatchDays(HATCH_DAYS_MAX),
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
			if (maxNegCounter > NEGLECT_MAX) {
				this->alive = false;
			}
		}

		hatchDays += NEGLECT_PENALTY;
	}

	// Egg hatches when it catches up with the required hatching time
	if (currDays >= hatchDays) {
		this->hatched = true;
	}

	currDays++;
}