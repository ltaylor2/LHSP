#pragma once

#include <vector>
#include <random>

enum class Sex { male, female };
enum class State { incubating, foraging };

class Parent {

public:

	// Constructor
	// Parameters:
	//		Sex sex_ = Biological sex of the adult
	Parent(Sex sex_);

	// Parent behavior
	void parentDay();

	// Setters
	void setState(State state_) { state = state_ ; }
	void setEnergy(double energy_) { energy = energy_; }

	// Getters
	State getState() { return state; }
	State getPreviousDayState() { return previousDayState; }

	double getEnergy() { return energy; }

	int getIncubationDays() { return incubationDays; }
	Sex getSex() { return sex; }

private:

		// Initial petrel energy, 766 kJ at the beggining of an incubation season (Ricklefs et al. 1986)
		constexpr static double BASE_ENERGY = 766;

		// When you have to move
		constexpr static double MIN_ENERGY_THRESHOLD = 0.0;

		// Basal metabolic rate, energy loss from incubation, 51.5 kJ/day (Ricklefs et al. 1986).
		// Blackmer et al. (2005) closely agrees.
		constexpr static double BMR = 51.1;

	    // using the equations from (Montevecchi et al 1992) for FMR and ME
	    // where ME(+) kJ/day = (48.8 +- 48.0) + (6.62 +- 2.73) * x hrs/day
	    // and where FMR(-) kJ/day = (85.8 +- 6.5) + (3.13 +- 0.48) * x hrs/day 
	    // thus max = max(ME) - min(FMR) using SD's and 24 hrs = 321.2 - 142.9 = 178.3
	    // and  min = min(ME) - max(FMR) using SD's and 24 hrs = 94.16 - 178.94 = -84.94
	    // to convert to a normal distribution, the mean = 46.68 and the sd = 131.62
	    // TODO reconsider normal methods
	    constexpr static double FORAGING_MIN = -84.94;
	    constexpr static double FORAGING_MAX = 178.3;
	    constexpr static double FORAGING_MEAN = 46.68;
	    constexpr static double FORAGING_SD = 131.62;

	    // use the above foraging values to construct a normal distribution for foraging values;
	   	std::normal_distribution<double> foragingDistribution;
  		std::default_random_engine rand;

	    // behavior based on the current state
	    void forage();
	    void incubate();

	    // reset the day counter
	    void resetDays();

	   	// state change functions
	   	double stopForagingProb();
	   	double stopIncubatingProb();

	   	Sex sex;	
	   	Parent* mate;
	   	State state;
	   	State previousDayState;
	   	double energy;

	   	int incubationDays;
	   	std::vector<int> incubationBouts;

	   	int foragingDays;
	   	std::vector<int> foragingBouts;
};