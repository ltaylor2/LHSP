#pragma once

/*
A Leach's Storm-petrel egg, sitting in a comfy burrow
*/ 
class Egg {
	
public:

	// Constructor
	Egg();					

	/*
	Egg Behavior, where the egg is incubated (moving towards hatch date) 
	or suffers neglect (moving further from hatch date and dying if 
	neglected too long)
	@param incubated is at least one parent incubating the egg?
	*/
	void eggDay(bool incubated);							

	// Getters
	bool isAlive() { return this->alive; }
	bool isHatched() { return this->hatched; }

	int getIncubationDays() { return this->currDays; }
	double getMaxHatchDays() { return this-> maxHatchDays; }
	int getTotNeg() { return this->totNegCounter; }
	int getMaxNeg() { return this->maxNegCounter; }
	double getEggCost() { return this->eggCost; }

private:

	// Minimum observed incubation period (Huntington et al. 1996)
	constexpr static double START_HATCH_DAYS = 37.0;

	// High number as an upper limit on egg hatching
	constexpr static double HATCH_DAYS_MAX = 60;

    // Mean energetic contents of a single egg (kJ) from Montevecchi et al. 1983
	constexpr static double EGG_COST = 69.7;

	/*
	Neglect comes with a developmental cost, increases the necessary
	length of incubation.

	Wheelwright and Boersma (1979) fit a line for Fork-Tailed Storm-Petrels,
	with a slope of 0.7 for (days fully incubated) ~ (days neglect).
	Each day of neglect is thus expected to add (1/0.7)=1.43 days
	to required incubation time.
	*/
	constexpr static double NEGLECT_PENALTY = 1.43;

	/*
	Maximum conseq. neglect before hatch failure 
	(based on maximum values from Wheelwright and Boersma (1979)
	in Fork-tailed Storm-petrels, 
	matching anecdotal value from LT for Leach's Storm-Petrels
	*/
	constexpr static int NEGLECT_MAX = 7;

	bool alive;	         // is egg alive? 
	bool hatched;		 // is egg hatched?

	double eggCost;

	double currDays;	     // egg age (days) 
	double hatchDays; 	     // current total incubation days required until
	double maxHatchDays; 	 // cutoff before hatching fails due to time limit (e.g., breeding window ends)

	int currNegCounter;	      // current consecutive days of neglect
	int totNegCounter;	      // totals days of neglect
	int maxNegCounter;	      // maximum consecutive days of neglect
};