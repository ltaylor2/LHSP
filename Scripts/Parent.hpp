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

	/*
	Parent behavior over a single day.
	If incubating, incubate.
	If foraging, forage.
	See individual functions for state-specific details.
	*/
	void parentDay();

	/*
	Function that changes states, called once the
	thresholds for state changes have actually been tested.
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
	void setDidOverlap(bool didOverlap_) { this->didOverlap = didOverlap_; }
  void setSupplementalParent(bool isSupplemental_) { this->isSupplemental = isSupplemental_; }

  void receiveEnergy(double delivery_) { this->energy = this->energy + delivery_; }

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

  double deliverEnergy() { return this->deliveredEnergy; }

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

	void incubate();
	void forage();

  bool stopIncubating();
 	bool stopForaging();

  Sex sex;				                  // individual's sex
  bool alive;				                // is the parent alive?
  bool isSupplemental;              // is this a supplemental (foraging delivery) parent?
	std::mt19937* randGen;			      // ptr to random device

  State state;				              // current state
  State previousDayState;			      // state during the previous day

  double energy;				            // current energy value (kJ)

  double baseEnergy;			          // starting energy value
  double incubatingMetabolism;		  // daily metabolism cost for incubation
  double foragingMetabolism;		    // daily metabolism cost for foraging

  double maxEnergyThresh;			      // satiation threshold (foraging->incubating)
  double minEnergyThresh;			      // hunger threshold (incubating->foraging)

  double foragingMean;			        // mean for distribution of foraging intake values
  double foragingSD;                // standard deviation for distribution of foraging intake values

  double deliveredEnergy;           // The delivered energy at the end of a foraging bout.

	// Normal distribution to draw stochastic foraging energy intakes
  std::normal_distribution<double> foragingDistribution;

  bool didOverlap;			            // did the last incubation bout end in an overlap?
  
  std::vector<double> energyRecord;	// energy values across all days

  int incubationDays;			          // current consecutive incubation days
  std::vector<int> incubationBouts;	// incubation bout record

  int foragingDays;			            // current consecutive foraging days
  std::vector<int> foragingBouts;		// foraging bout record

  bool firstBout;				            // is it the adult's first bout?
};
