#include "Egg.hpp"

// Constructor
Egg::Egg():
	isAlive(true),
	isHatched(false),
	currDays(0),
	hatchDays(START_HATCH_DAYS),
	negCounter(0),
	maxNegCounter(0)
{}

void Egg:eggDay(bool incubated)
{

	// incubated eggs reset the neglect counter
	if (incubated) {
		negCounter = 0;
	} 

	// neglected eggs suffer an incubation penalty
	else {
		negCounter++;
		if (negCounter > maxNegCounter) {
			maxNegCounter = negCounter;
		}

		hatchDays += NEGLECT_PENALTY;
	}

	if (currDays >= hatchDays) {
		isHatched = true;
	}


	// move onto the next day (from the perspective of the egg) 
	currDays++;
}