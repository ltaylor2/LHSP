#pragma once

class Egg {
	
public:
	// Constructor
	Egg();					

	// egg behavior
	// Parameters:
	//		bool incubated = is a parent incubating the egg?
	void eggDay(bool incubated);							

	// Getters
	bool isAlive() { return isAlive; }
	bool isHatched() { return isHatched; }
	int getMaxNeg() { return maxNegCounter; }


private:

	// Minimum observed incubation period (Hunting et al. 1996)
	constexpr static double START_HATCH_DAYS = 37.0;

	// Very high number as an upper limit on egg hatching
	constexpr static double HATCH_DAYS_MAX = 60;

	// Boersma and Wheelwright (1979) fit a line for Fork-Tailed Storm-petrels,
	// with a slope of 0.7 for (days fully incubated) ~ (days neglect).
	// Each day of neglect is thus expected to add (1 / 0.7) = 1.43 days of required incubation.
	constexpr static double NEGLECT_PENALTY = 1.43;

	bool isAlive;			// is egg alive?
	bool isHatched;			// is egg hatched?

	// counters for current and required incubation periods (days)
	bool currDays;
	double hatchDays;

	// what is the current neglect streak (days)
	int negCounter;

	// what is the maximum neglect streak (days)
	int maxNegCounter;
};