#include "Parent.hpp"

Parent::Parent(Sex sex_):
	sex(sex_),
	energy(BASE_ENERGY),
	energyRecord(std::vector<double>()),
	incubationDays(0),
	incubationBouts(std::vector<int>()),
	foragingDays(0),
	foragingBouts(std::vector<int>()),
	foragingDistribution(std::normal_distribution<double>(FORAGING_MEAN, FORAGING_SD))
{
	auto seed = std::chrono::high_resolution_clock::now().time_since_epoch().count();
	rand = std::mt19937(seed);
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
	double foragingEnergy = foragingDistribution(rand);

	// // Metabolic intake, concatenated at min/max values
	if (foragingEnergy < FORAGING_MIN) {
		foragingEnergy = FORAGING_MIN;
	} else if (foragingEnergy > FORAGING_MAX) {
		foragingEnergy = FORAGING_MAX;
	}

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
	if (this->energy >= BASE_ENERGY) {
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
		this->foragingBouts.push_back(this->foragingDays);
		this->foragingDays = 0;
		this->state = State::incubating;
	}
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