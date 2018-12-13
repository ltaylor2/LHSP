#include "Parent.hpp"

Parent::Parent(Sex sex_, std::mt19937* randGen_):
	foragingDistribution(std::normal_distribution<double>(FORAGING_MEAN, FORAGING_SD)),
	sex(sex_),
	energy(BASE_ENERGY),
	returnEnergyThreshold(BASE_ENERGY),
	randGen(randGen_),
	energyRecord(std::vector<double>()),
	incubationDays(0),
	incubationBouts(std::vector<int>()),
	foragingDays(0),
	foragingBouts(std::vector<int>()),
	firstBout(true)
{
	// males begin the breeding season foraging
	// females (who have just laid the egg), begin by incubating

	this->state = State::foraging;
	this->previousDayState = State::foraging;

	if (sex == Sex::female) {
		this->state = State::incubating;
		this->previousDayState = State::incubating;
	}		
}

void Parent::parentDay()
{
	energyRecord.push_back(this->energy);
	
	if (this->state == State::incubating) {
		incubate();
	} else if (this->state == State::foraging) {
		forage();
	}
}

void Parent::incubate()
{
	this->energy -= INCUBATING_METABOLISM;
	this->incubationDays++;

	if (stopIncubating()) {
		changeState();
	}

	this->previousDayState = State::incubating;
}

void Parent::forage()
{
	// draw from the normal distribution of foraging calorie values
	double foragingEnergy = foragingDistribution(*randGen);

	this->energy += foragingEnergy;

	// subtract at-sea metabolic rate
	this->energy -= FORAGING_METABOLISM;

	this->foragingDays++;

	if (stopForaging()) {
		changeState();
	}

	this->previousDayState = State::foraging;
}

bool Parent::stopIncubating() {
	if (this->energy <= MIN_ENERGY_THRESHOLD) {
		return true;
	}
	return false;
}

bool Parent::stopForaging() {
	if (this->energy >= returnEnergyThreshold) {
		return true;
	}
	return false;
}

void Parent::changeState()
{
	if (this->state == State::incubating) {
		this->incubationBouts.push_back(this->incubationDays);
		this->incubationDays = 0;
		this->state = State::foraging;
	} else if (this->state == State::foraging) {
		// NOTE when an adult begins in the foraging state with BASE energy
		// (like males in the current build), we want to drop this first errant 1-day record
		if (!firstBout) {
			this->foragingBouts.push_back(this->foragingDays);
		}
		this->foragingDays = 0;
		this->state = State::incubating;
	}
	firstBout = false;
}

std::string Parent::getStrState() {
	std::string s = "";
	if (this->state == State::incubating) {
		s = "Incubating";
	} else if (this->state == State::foraging) {
		s = "Foraging";
	}

	return s;
}