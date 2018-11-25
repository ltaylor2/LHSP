#include "Parent.hpp"

Parent::Parent(Sex sex_):
	sex(sex_),
	energy(BASE_ENERGY),
	incubationDays(0),
	incubationBouts(std::vector<int>()),
	foragingDays(0),
	foragingBouts(std::vector<int>()),
	foragingDistribution(std::normal_distribution<double>(FORAGING_MEAN, FORAGING_SD)),
	rand(std::default_random_engine())
{
	// males begin the breeding season foraging
	// females (who have just laid the egg), begin by incubating
	state = State::foraging;
	previousDayState = State::foraging;

	if (sex == Sex::female) {
		state = State::incubating;
		previousDayState = State::incubating;
	}		
}

void parentDay()
{
	if (this.state == State::incubate) {
		incubate();
	} else if (this.state == State::foraging) {
		forage();
	}
}

void incubate()
{
	energy -= BMR;
	incubationDays++;

	if (energy <= MIN_ENERGY_THRESHOLD) {
		changeState();
	}
}

void forage()
{
	// draw from the normal distribution of foraging calorie values
	double foragingEnergy = foragingDistribution(rand);

	// concatenate distribution at known min/max values
	if (foragingEnergy < FORAGING_MIN) {
		foragingEnergy = FORAGING_MIN;
	} else if (foragingEnergy > FORAGING_MAX) {
		foragingEnergy = FORAGING_MAX;
	}

	// remember, this can still be a negative change!
	energy += foragingEnergy;

	foragingDays++;

	// TODO NEXT STOP FORAGING PROBABILITIES
}

void changeState()
{
	if (state == State::incubating) {
		incubationBouts.push(incubationDays);
		incubationDays = 0;
		state = State::foraging;
	} else if (state == State::foraging) {
		foragingBouts.push(foragingDays);
		foraginDays = 0;
		state = State::incubating;
	}
}
