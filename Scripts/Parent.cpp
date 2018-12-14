#include "Parent.hpp"

Parent::Parent(Sex sex_, std::mt19937* randGen_):
	foragingDistribution(std::normal_distribution<double>(FORAGING_MEAN, 
														  FORAGING_SD)),
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
	/*
		Males begin the breeding season in the foraging state,
		while females begin the breeding season in the incubating state
	*/
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
	
	// Act out state behavior
	if (this->state == State::incubating) {
		incubate();
	} else if (this->state == State::foraging) {
		forage();
	}
}


void Parent::changeState()
{
	if (this->state == State::incubating) {
		this->incubationBouts.push_back(this->incubationDays);
		this->incubationDays = 0;
		this->state = State::foraging;
	} else if (this->state == State::foraging) {
		/* 
			NOTE when an adult begins in the foraging state with BASE energy
		 		(like males in the current build), we want to drop this first 
		 		errant 1-day record
		*/
		if (!firstBout) {
			this->foragingBouts.push_back(this->foragingDays);
		}
		this->foragingDays = 0;
		this->state = State::incubating;
	}

	firstBout = false;
}

void Parent::incubate()
{
	this->incubationDays++;

	// Lose energy to metabolism
	this->energy -= INCUBATING_METABOLISM;

	// Incubating -> Foraging depending on energy
	if (stopIncubating()) {
		changeState();
	}

	this->previousDayState = State::incubating;
}

void Parent::forage()
{
	this->foragingDays++;

	// Gain metabolic intake given normal distribution of energy outcomes
	double foragingEnergy = foragingDistribution(*randGen);
	this->energy += foragingEnergy;

	// Lose energy to metabolism
	this->energy -= FORAGING_METABOLISM;

	// Foraging -> Incubating depending on energy
	if (stopForaging()) {
		changeState();
	}

	this->previousDayState = State::foraging;
}

bool Parent::stopIncubating() 
{
	// Deterministic binary minimum threshold
	if (this->energy < MIN_ENERGY_THRESHOLD) {
		return true;
	}
	return false;
}

bool Parent::stopForaging() 
{
	// Deterministic binary maximum threshold
	if (this->energy > returnEnergyThreshold) {
		return true;
	}
	return false;
}

// std::string Parent::getStrState() {
// 	// Why oh why do I not know an easier way to convert enums to strings?
// 	std::string s = "";
// 	if (this->state == State::incubating) {
// 		s = "Incubating";
// 	} else if (this->state == State::foraging) {
// 		s = "Foraging";
// 	}

// 	return s;
// }