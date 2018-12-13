#include "Egg.hpp"

// Constructor
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

	// incubated eggs reset the neglect counter
	if (incubated) {
		this->currNegCounter = 0;
	} 

	// neglected eggs suffer an incubation penalty
	else {
		currNegCounter++;
		totNegCounter++;
		if (currNegCounter > maxNegCounter) {
			this->maxNegCounter = currNegCounter;
		}

		hatchDays += NEGLECT_PENALTY;
	}

	if (currDays >= hatchDays) {
		this->hatched = true;
	}

	// move onto the next day (from the perspective of the egg) 
	currDays++;
}