#pragma once

/*
	A Leach's Storm-petrel egg, sitting in a comfy burrow
*/ 
class Egg {
	
public:

	// Constructor
	Egg();					

	/*
		Egg Behavior, where the egg aquires incubation or suffers neglect, 
		altering the distance to hatch date

		@param incubated is at least one parent incubating the egg?
	*/
	void eggDay(bool incubated);							

	// Getters
	bool isAlive() { return this->alive; }
	bool isHatched() { return this->hatched; }

	int getIncubationDays() { return this->currDays; }

	int getTotNeg() { return this->totNegCounter; }
	int getMaxNeg() { return this->maxNegCounter; }

private:

	// Parameters simplified for Life History Evolution course report
	constexpr static double START_HATCH_DAYS = 30.0;

	bool alive;		// is egg alive? (not used in this build)
	bool hatched;		// is egg hatched?

	double currDays;	// days record
	double hatchDays; 	// incubation days required

	int currNegCounter;	// current consecutive days of neglect
	int totNegCounter;	// totals days of neglect
	int maxNegCounter;	// maximum consecutive days of neglect
};