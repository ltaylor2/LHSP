#pragma once

#include <vector>
#include <random>
#include <chrono>
#include <iostream>

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
	@param randGen_ ptr to a single-seeded random number device
	*/
	Parent(Sex sex_, std::mt19937* randGen_);

	// Parent behavior, including incubating, foraging, and/or changing states
	void parentDay();

	/*
	Changes state incubating<->foraging
	NOTE this guarantees a state change, and is called after thresholds are checked 
	*/
	void changeState();
	
	// Setters
	void setState(State state_) { this->state = state_ ; }
	void setEnergy(double energy_) { this->energy = energy_; }
	void setBaseEnergy(double baseEnergy_) { this->baseEnergy = baseEnergy_; }
	void setIncubatingMetabolism(double incubatingMetabolism_) { this->incubatingMetabolism = incubatingMetabolism_; }
	void setForagingMetabolism(double foragingMetabolism_) { this->foragingMetabolism = foragingMetabolism_; }
	void setMaxEnergyThresh(double maxEnergyThresh_) { this->maxEnergyThresh = maxEnergyThresh_; }
	void setMinEnergyThresh(double minEnergyThresh_) { this->minEnergyThresh = minEnergyThresh_; }
	void setForagingDistribution(double foragingMean_, double foragingSD_);
	void setShouldCompensate(bool shouldCompensate_) { this->shouldCompensate = shouldCompensate_; }
	void setShouldRetaliate(bool shouldRetaliate_) { this->shouldRetaliate = shouldRetaliate_; }
	void setDidOverlap(bool didOverlap_) { this->didOverlap = didOverlap_; }
	void setReactDelay(int reactDelay_) { this->reactDelay = reactDelay_; }

	// Getters
	Sex getSex() { return this->sex; }
	bool isAlive() { return this->alive; }
	double getEnergy() { return this->energy; }
	double getbaseEnergy() { return this->baseEnergy; }
	double getIncubatingMetabolism() { return this->incubatingMetabolism; }
	double getForagingMetabolism() { return this->foragingMetabolism; }
	double getMaxEnergyThresh() { return this->maxEnergyThresh; }
	double getMinEnergyThresh() { return this->minEnergyThresh; }
	double getForagingMean() { return this->foragingMean; }
	double getForagingSD() { return this->foragingSD; }

	State getState() { return this->state; }
	std::string getStrState(); // str printable form
	State getPreviousDayState() { return this->previousDayState; }
	std::vector<double> getEnergyRecord() { return this->energyRecord; }
	int getIncubationDays() { return this->incubationDays; }

	std::vector<int> getIncubationBouts() { return this->incubationBouts; }
	std::vector<int> getForagingBouts() { return this->foragingBouts; }

private:
	/*
	Parameters for the mean and standard deviation for foraging,
	in kJ of metabolic intake. Modeled as a normal distribution.
	Montevecchi et al. (1992) for Newfoundland parameters
	*/
		constexpr static double FORAGING_MEAN = 162;
		constexpr static double FORAGING_SD = 47;

	/*
	Initial energy buffer at the beginning of the incubation season (kJ)
	Derived from the mean energy adults had at the beginning of observed
	incubation bouts in Ricklefs et al. (1986)
	*/ 
	constexpr static double BASE_ENERGY = 766;


	/*
	Metabolic rate requirements while incubating and foraging (kJ/day)
	From Ricklefs et al. (1986) 
	and further discussion in Montevecchi et al. (1992)
	*/
	constexpr static double INCUBATING_METABOLISM = 52;
	constexpr static double FORAGING_METABOLISM = 123;

	/* 
	The deterministic threshold above which foraging ceases 
	(at the end of the day), here equaling the mean amount of energy at
	which parents were found to start incubating (BASE_ENERGY)
	*/
	constexpr static double MAX_ENERGY_THRESHOLD = BASE_ENERGY;

	/*
	The deterministc threshold below which incubation ceases
	(at the end of the day), here equaling the metabolic cost of
	foraging for a day.
	*/
	constexpr static double MIN_ENERGY_THRESHOLD = FORAGING_METABOLISM;
	
	constexpr static int REACT_DELAY = 1;
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
   	foraging deterministically stops when the energy of the adult
   	passes above strict threshold.
   	*/
  	void forage();

    	// State change functions.
    	// @ret TRUE if should change
   	bool stopIncubating();
   	bool stopForaging();

   	Sex sex;				// individual's sex
   	bool alive;				// is the parent alive?
	std::mt19937* randGen;			// ptr to random device

   	State state;				// current state
   	State previousDayState;			// state during the previous day

   	double energy;				// current energy value (kJ)

   	double baseEnergy;
   	double incubatingMetabolism;
   	double foragingMetabolism;

   	double maxEnergyThresh;
   	double minEnergyThresh;

   	double foragingMean;
   	double foragingSD;

	// Normal distribution to draw stochastic foraging energy intakes
   	std::normal_distribution<double> foragingDistribution;

   	bool shouldCompensate;
   	bool shouldRetaliate;
   	bool didOverlap;

   	int reactDelay;
   	int currReactDelay;

   	std::vector<double> energyRecord;	// energy values across all days

   	int incubationDays;					// current consecutive inc. days
   	std::vector<int> incubationBouts;	// incubation bout record

   	int foragingDays;					// current consecutive forg. days
   	std::vector<int> foragingBouts;		// foraging bout record

   	bool firstBout;						// is it the adult's first bout?
};