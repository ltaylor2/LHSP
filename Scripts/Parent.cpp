#include "Parent.hpp"

Parent::Parent(Sex sex_, std::mt19937* randGen_):
	sex(sex_),
	alive(true),
	randGen(randGen_),
	energy(BASE_ENERGY),
	baseEnergy(BASE_ENERGY),
	incubatingMetabolism(INCUBATING_METABOLISM),
	foragingMetabolism(FORAGING_METABOLISM),
	maxEnergyThresh(MAX_ENERGY_THRESHOLD),
	minEnergyThresh(MIN_ENERGY_THRESHOLD),
	foragingMean(FORAGING_MEAN),
	foragingSD(FORAGING_SD),
	foragingDistribution(std::normal_distribution<double>(foragingMean, 
							      foragingSD)),
	shouldCompensate(false),
	shouldRetaliate(false),
	didOverlap(false),
	reactDelay(REACT_DELAY),
	currReactDelay(0),
	energyRecord(std::vector<double>()),
	incubationDays(0),
	incubationBouts(std::vector<int>()),
	foragingDays(0),
	foragingBouts(std::vector<int>()),
	firstBout(true)
{
	/*
	Male begin the incubation period incubating, females begin foraging 
	*/
	this->state = State::incubating;
	this->previousDayState = State::incubating;

	if (this->sex == Sex::female) {
		this->state = State::foraging;
		this->previousDayState = State::foraging;
		didOverlap = true;
	}
}

void Parent::parentDay()
{
	// Record energy values for each day
	energyRecord.push_back(this->energy);
	
	// Did the parent die?
	if (this->energy <= 0) {
		this->alive = false;
	}

	// Act out state behavior
	if (this->state == State::incubating) {
		incubate();
	} else if (this->state == State::foraging) {
		forage();
	}

}

void Parent::changeState()
{
	// Switch from incubating to foraging
	if (this->state == State::incubating) {
		if (!firstBout) {
			// Record bout lengths for all but first bout
			this->incubationBouts.push_back(this->incubationDays);
		}

		this->incubationDays = 0;
		this->state = State::foraging;

		firstBout = false;

		// Overlap values are overwritten if the overlap
		// actually occurs in the breadingSeason() function.
		didOverlap = false;

	// Switch from foraging to incubating
	} else if (this->state == State::foraging) {
		if (!firstBout) {
			// Record bout lengths for all but first bout
			this->foragingBouts.push_back(this->foragingDays);
		}
		this->foragingDays = 0;
		this->state = State::incubating;

		firstBout = false;
	}
}

void Parent::incubate()
{
	this->incubationDays++;

	// Lose energy to metabolism
	this->energy -= incubatingMetabolism;

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

	// Gain metabolic intake given normal distribution of energy outcomes
	double foragingEnergy = foragingDistribution(*randGen);
	this->energy += foragingEnergy;

	// Lose energy to metabolism
	this->energy -= foragingMetabolism;

	// Foraging -> Incubating depending on energy
	if (stopForaging()) {
		changeState();
	}

	this->previousDayState = State::foraging;
}


bool Parent::stopIncubating() 
{
	// Deterministic boolean minimum threshold
	if (this->energy < minEnergyThresh) {
		/*
		If the parent should compensate, stay an extra day regardless
		of energy level.
		*/
		if (shouldCompensate && !didOverlap && currReactDelay < reactDelay) {
			currReactDelay++;
		} else {
			didOverlap = false;
			currReactDelay = 0;

			// Stop incubating
			return true;
		}
	}
	// Don't stop incubating
	return false;
}

bool Parent::stopForaging() 
{
	// Deterministic boolean maximum threshold
	if (this->energy > maxEnergyThresh && this->foragingDays > 1) {
		if (shouldRetaliate && !didOverlap && currReactDelay < reactDelay) {
			currReactDelay++;
		} else {
			currReactDelay = 0;

			// Stop foraging
			return true;
		}
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
	}

	return s;
}

void Parent::setForagingDistribution(double foragingMean_, double foragingSD_)
{ 
	this->foragingMean = foragingMean_;
	this->foragingSD = foragingSD_;

	this->foragingDistribution = 
		std::normal_distribution<double>(foragingMean_, foragingSD_); 
}
