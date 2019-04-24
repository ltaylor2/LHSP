#pragma once

#include <vector>
#include <random>
#include <chrono>

enum class Sex { male, female };
enum class State { incubating, foraging };

/*
	A breeding adult Leach's Storm-petrel parent, flying back and forth from
	the foraging ground to the breeding ground
*/
class Parent {

public:

	/* 
		Constructor
	
		@param sex_ sex of the bird (enum, male or female)
	   		   randGen_ ptr to a single-seeded random number device
	*/
	Parent(Sex sex_, std::mt19937* randGen_);

	// Parent behavior, including incubating, foraging, and/or changing states
	void parentDay();

	/*
		Changes state incubating<->foraging
	 	NOTE this guarantees a state change, and is called after
	 		thresholds are checked 
	*/
	void changeState();
	
	// Setters
	void setState(State state_) { this->state = state_; }
	void setEnergy(double energy_) { this->energy = energy_; }

	void setIncubationMetabolism(double incubationMetabolism_) { this->incubationMetabolism = incubationMetabolism_; }
	void setForagingMetabolism(double foragingMetabolism_) { this->foragingMetabolism = foragingMetabolism_; }
	void setMinEnergyThreshold(double minEnergyThreshold_) { this->minEnergyThreshold = minEnergyThreshold_; }
	void setMaxEnergyThreshold(double maxEnergyThreshold_) { this->maxEnergyThreshold = maxEnergyThreshold_; }

	void setForagingDistribution(double mean, double sd)
	{ 
		this->foragingDistribution = std::normal_distribution<double>(mean, sd); 
	}
	
	// Getters
	Sex getSex() { return this->sex; }

	State getState() { return this->state; }
	// std::string getStrState(); // str printable form
	State getPreviousDayState() { return this->previousDayState; }

	double getEnergy() { return this->energy; }

	std::vector<double> getEnergyRecord() { return this->energyRecord; }
	int getIncubationDays() { return this->incubationDays; }

	std::vector<int> getIncubationBouts() { return this->incubationBouts; }
	std::vector<int> getForagingBouts() { return this->foragingBouts; }

	double getIncubationMetabolism() {return this->incubationMetabolism; }
	double getForagingMetabolism() { return this->foragingMetabolism; }
	double getMinEnergyThreshold() { return this->minEnergyThreshold; }
	double getMaxEnergyThreshold() { return this->maxEnergyThreshold; }

	bool isAlive() { return this->alive; }
	
	// Defaults for param initialization
	constexpr static double BASE_ENERGY 	      = 100;
	constexpr static double INCUBATION_METABOLISM = 10;
	constexpr static double FORAGING_METABOLISM   = 20;
	constexpr static double MIN_ENERGY_THRESHOLD  = 20;
	constexpr static double MAX_ENERGY_THRESHOLD  = 100;

    	constexpr static double FORAGING_MEAN = 20;
    	constexpr static double FORAGING_SD   = 5;		

private:

	// Normal distribution to draw stochastic foraging energy intakes
	std::normal_distribution<double> foragingDistribution;

	/*
	   A day of incubation behavior while in the incubating state.
	   While in the nesting burrow, the adult loses a set amount of energy
	   to metabolism, and can gain no energy.
	   Incubation deterministically stops when the energy of the 
	   adult passes below a strict threshold
	*/
	void incubate();

	/*
	   A day of foraging behavior while in the foraging state.
	   On the foraging grounds, the adult loses a set amount
	   of energy to metabolism, but gains a stochastic amount of energy
	   from a normal distribution of metabolic intake values.
	   Foraging deterministically stops when the energy of the adult
	   passes above strict threshold.
	*/
	void forage();

	// State change functions.
	// @ret TRUE 
	bool stopIncubating();
	bool stopForaging();

	Sex sex;				// individual's sex

	State state;				// current state
	State previousDayState;			// state during the previous day

	std::mt19937* randGen;			// ptr to random device

	std::vector<double> energyRecord;	// energy values across all days

	int incubationDays;			// current consecutive inc. days
	std::vector<int> incubationBouts;	// incubation bout record

	int foragingDays;			// current consecutive forg. days
	std::vector<int> foragingBouts;		// foraging bout record

	bool firstBout;				// is it the adult's first bout?

	// All dynamic for life history course report
	double energy;				// current energy value (kJ)
	bool alive;
	double incubationMetabolism;
	double foragingMetabolism;
	double minEnergyThreshold;
	double maxEnergyThreshold;

};