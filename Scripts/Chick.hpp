#pragma once

/*
	A Leach's Storm-petrel chick, growing in a comfy burrow
*/ 
class Chick {
	
public:

	// Constructor
	Chick();					

	/*
	Chick Behavior, where parent feeding alters the growth of the chick
	@param numParents how many parents are going to feed the chick today?
	*/
	void chickDay(int numParents);							

	// Getters
	bool isAlive() { return this->alive; }
	bool isHatched() { return this->hatched; }
	bool isBrooding() { return this->brooding; }
	bool isFledged() { return this->fledged; }

private:

	// From Ricklefs et al. 1980 Table 2
	constexpr static double FLEDGE_AGE = 60;

	// From Ricklefs et al. 1980 Table 2, Col 10
	constexpr static double AGE_SPECIFIC_METABOLISM[7] = {47.0,
							      55.7,
							      65.8,
							      80.5,
							      89.8,
							      97.0,
							      95.3}

	bool alive;		// is chick still alive? 
	bool hatched;		// is chick hatched from egg?
	bool brooding;		// is chick brooding (is age 0-3 days?)
	bool fledged;		// is chick fledged?

	int age;
	double energy;


};