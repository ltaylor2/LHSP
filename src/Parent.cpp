#include "Parent.hpp"

Parent::Parent(Sex sex_, std::mt19937* randGen_):
	sex(sex_),
	randGen(randGen_),
	energy(BASE_ENERGY),
	baseEnergy(BASE_ENERGY),
	incubatingMetabolism(INCUBATING_METABOLISM),
	foragingMetabolism(FORAGING_METABOLISM),
    minEnergyThresh(MIN_ENERGY_THRESHOLD),
	maxEnergyThresh(MAX_ENERGY_THRESHOLD),
	foragingMean(FORAGING_MEAN),
	foragingSD(FORAGING_SD),
	foragingDistribution(std::normal_distribution<double>(foragingMean, foragingSD)),
    foragingDays(0),
	energyRecord(std::vector<double>())
{
	/*
	Male begin the incubation period incubating, females begin foraging
	*/
	this->state = State::incubating;
	this->previousDayState = State::incubating;

	if (this->sex == Sex::female) {
		this->state = State::foraging;
		this->previousDayState = State::foraging;
	}
}

void Parent::parentDay()
{
	if (this->state != State::dead) {
		// Record energy values for each day
		this->energyRecord.push_back(this->energy);
	}

	// Did the parent die?
	if (this->energy <= 0) {
		this->state = State::dead;
	}

	if (this->state != State::dead) {
	    if (this->state == State::incubating) { incubate(); } 
        else if (this->state == State::foraging) { forage(); }
	}
}

void Parent::changeState()
{
	// Switch from incubating to foraging
	if (this->state == State::incubating) {
		this->state = State::foraging;

	// Switch from foraging to incubating
	} else if (this->state == State::foraging) {
		this->state = State::incubating;
        this->foragingDays = 0;
	}
}

void Parent::incubate()
{
	// Lose energy to metabolism
	this->energy -= this->incubatingMetabolism;

	// Incubating -> Foraging depending on energy
	if (stopIncubating()) {
		changeState();
	}

	this->previousDayState = State::incubating;
}

/*
Foraging behavior.
Parents lose energy to (heightened) metabolism,
and have the change to gain energy as a draw from
a random distribution.
*/
void Parent::forage()
{
	this->foragingDays++;

	// Lose energy to metabolism
	this->energy -= this->foragingMetabolism;

	// Gain metabolic intake given normal distribution of energy outcomes
	double foragingEnergy = foragingDistribution(*randGen);
	this->energy += foragingEnergy;

	// Foraging -> Incubating depending on energy
	if (stopForaging()) {
		changeState();
	}

	this->previousDayState = State::foraging;
}

bool Parent::stopIncubating()
{
	// Deterministic boolean minimum threshold
	if (this->energy <= this->minEnergyThresh) {
    	// Stop incubating
		return true;
	}

	// Don't stop incubating
	return false;
}

bool Parent::stopForaging()
{
	// Deterministic boolean maximum threshold
	if (this->energy >= this->maxEnergyThresh && this->foragingDays > 1) {
    		// Stop foraging
    		return true;
	}

  	// Don't stop foraging
	return false;
}

std::string Parent::getStrState() {
	// Why oh why do I not know an easier way to convert enums to strings?
	std::string s = "";
	if (this->state == State::incubating) {
		s = "Incubating";
	} else if (this->state == State::foraging) {
		s = "Foraging";
	} else if (this->state == State::dead) {
		s = "Dead";
	}

	return s;
}

void Parent::setForagingDistribution(double foragingMean_, double foragingSD_)
{
	this->foragingMean = foragingMean_;
	this->foragingSD = foragingSD_;

	this->foragingDistribution = std::normal_distribution<double>(foragingMean_, foragingSD_);
}