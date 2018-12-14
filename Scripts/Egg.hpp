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

	// Very high number as an upper limit on egg hatching
	constexpr static double HATCH_DAYS_MAX = 60;

    // Mean energetic contents of a single egg from Montevecchi et al. 1983
    constexpr static double EGG_COST = 69.7;

private:

	// Minimum observed incubation period (Huntington et al. 1996)
	constexpr static double START_HATCH_DAYS = 37.0;

	/*
		Neglect comes with a developmental cost, increases the necessary
		length of incubation.

		Boersma and Wheelwright (1979) fit a line for Fork-Tailed Storm-petrels,
		with a slope of 0.7 for (days fully incubated) ~ (days neglect).
		Each day of neglect is thus expected to add (1/0.7)=1.43 days
		to required incubation time.
	*/
	constexpr static double NEGLECT_PENALTY = 1.43;

	bool alive;			// is egg alive? (not used in this build)
	bool hatched;		// is egg hatched?

	double currDays;	// days record
	double hatchDays; 	// incubation days required

	int currNegCounter;	// current consecutive days of neglect
	int totNegCounter;	// totals days of neglect
	int maxNegCounter;	// maximum consecutive days of neglect
};