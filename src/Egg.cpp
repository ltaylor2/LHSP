#include "Egg.hpp"

/*
Constructor (see Egg.hpp file).
C++11 initialization of instance variables.
*/
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

/*
Egg behavior for a single day.
@param incubated is the egg incubated for the day?
*/
void Egg::eggDay(bool incubated)
{
	// Keeping track of all days (incubated or not)
	this->currDays++;

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

			// Eggs which exceed the maximum neglect streak value die completely. 
			if (maxNegCounter > NEGLECT_MAX) {
				this->alive = false;
			}
		}

		this->hatchDays += NEGLECT_PENALTY;
	}

	// Egg hatches when it catches up with the required hatching time
	if (this->currDays >= this->hatchDays) {
		this->hatched = true;
	}
}