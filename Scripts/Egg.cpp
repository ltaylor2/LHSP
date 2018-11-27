#include "Egg.hpp"

// Constructor
Egg::Egg():
	alive(true),
	hatched(false),
	currDays(0),
	hatchDays(START_HATCH_DAYS),
	negCounter(0),
	maxNegCounter(0)
{}

void Egg::eggDay(bool incubated)
{

	// incubated eggs reset the neglect counter
	if (incubated) {
		this->negCounter = 0;
	} 

	// neglected eggs suffer an incubation penalty
	else {
		negCounter++;
		if (negCounter > maxNegCounter) {
			this->maxNegCounter = negCounter;
		}

		hatchDays += NEGLECT_PENALTY;
	}

	if (currDays >= hatchDays) {
		this->hatched = true;
	}

	// move onto the next day (from the perspective of the egg) 
	currDays++;
}