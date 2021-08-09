#include "Parent.hpp"

Parent::Parent(Sex sex_, std::mt19937* randGen_):
	sex(sex_),
  	isSupplemental(false),
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
	energyRecord(std::vector<double>()),
	incubationDays(0),
	incubationBouts(std::vector<int>()),
	foragingDays(0),
	foragingBouts(std::vector<int>()),
	firstBout(true),
	deadCounter(0)
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
		energyRecord.push_back(this->energy);
	}

	// Did the parent die?
	if (this->energy <= 0) {
		this->state = State::dead;

		if (this->previousDayState == State::incubating) {
			this->incubationBouts.push_back(this->incubationDays);
		}
		else if (this->previousDayState == State::foraging) {
			this->foragingBouts.push_back(this->foragingDays);
		}
		this->previousDayState = State::dead;
	}

	if (this->state != State::dead) {
	  // If this is a supplemental foraging parent, foraging deliveries are returned separately
	  if (this->isSupplemental) {
	    // reset delivered energy for each day
	    //    (stays 0 if the parent is still foraging)
	    this->deliveredEnergy = 0;

	    // Supplemental parents forage every day
	    forage();

	    // If the parent has hit the satitation threshold at the end of its last foraging bout,
	    //  it returns to the nest to drop off food (here we use the normal "incubating")
	    //  state from the full parental model as a key, extract the energy from the parent,
	    //  and then send it back on its way
	    if (this->state == State::incubating) {
	      this->deliveredEnergy = this->energy - this->minEnergyThresh;
	      this->energy = this->minEnergyThresh;
	      changeState();
	    }
	  }

	  else {
	    if (this->state == State::incubating) {
	      incubate();
	    } else if (this->state == State::foraging) {
	      forage();
	    }
	  }
	} 
	else {
		this->deadCounter++;
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

	// Lose energy to metabolism
	this->energy -= foragingMetabolism;

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
	if (this->energy <= minEnergyThresh) {
    	// Stop incubating
		return true;
	}

	// Don't stop incubating
	return false;
}

bool Parent::stopForaging()
{
	// Deterministic boolean maximum threshold
	if (this->energy >= maxEnergyThresh && this->foragingDays > 1) {
    		// Stop foraging
    		return true;
	}

  	// Don't stop foraging
	return false;
}

void Parent::pushLastBout()
{
	if (this->state == State::incubating) {
		this->incubationBouts.push_back(this->incubationDays);
	} else if (this->state == State::foraging) {
		this->foragingBouts.push_back(this->foragingDays);
	}
	return;
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

	this->foragingDistribution =
	std::normal_distribution<double>(foragingMean_, foragingSD_);
}