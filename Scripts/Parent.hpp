#pragma once

#include <vector>
#include <random>
#include <chrono>


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

	void changeState();
	
	// Setters
	void setState(State state_) { this->state = state_ ; }
	void setEnergy(double energy_) { this->energy = energy_; }

	// Getters
	State getState() { return this->state; }
	std::string getStrState();
	State getPreviousDayState() { return this->previousDayState; }

	double getEnergy() { return this->energy; }
	std::vector<double> getEnergyRecord() { return this->energyRecord; }

	int getIncubationDays() { return this->incubationDays; }
	Sex getSex() { return this->sex; }

	std::vector<int> getIncubationBouts() { return this->incubationBouts; }
	std::vector<int> getForagingBouts() { return this->foragingBouts; }

private:

		// Initial petrel energy, 766 kJ at the beginning of an incubation bout (Ricklefs et al. 1986, Montevecchi et al 1992)
		constexpr static double BASE_ENERGY = 766;

		// When you have to move (Ricklefs et al. 1986, Montevecci et al. 1992)
		constexpr static double MIN_ENERGY_THRESHOLD = 123;

		// Basal metabolic rate, energy loss from incubation, 52 kJ/day (Ricklefs et al. 1986, Montevecchi et al 1992).
		// Blackmer et al. (2005) closely agrees.
		constexpr static double INCUBATING_METABOLISM = 52;
		constexpr static double FORAGING_METABOLISM = 123;

		// From Montevvechi et al 1992 Table 3
	    // TODO reconsider normal methods
	    constexpr static double FORAGING_MIN = 74;
	    constexpr static double FORAGING_MAX = 221;
	    constexpr static double FORAGING_MEAN = 162;
	    constexpr static double FORAGING_SD = 47;

	    // use the above foraging values to construct a normal distribution for foraging values;
	   	std::normal_distribution<double> foragingDistribution;
  		std::mt19937 rand;

	    // behavior based on the current state
	    void forage();
	    void incubate();

	    // reset the day counter
	    void resetDays();

	   	// state change functions
	   	// returns TRUE if the bird should change state
	   	bool stopIncubating();
	   	bool stopForaging();

	   	Sex sex;	
	   	Parent* mate;
	   	State state;
	   	State previousDayState;
	   	double energy;

	   	std::vector<double> energyRecord;

	   	int incubationDays;
	   	std::vector<int> incubationBouts;

	   	int foragingDays;
	   	std::vector<int> foragingBouts;
};