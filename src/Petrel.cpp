#include <stdlib>
#include <random>
#include <chrono>
#include <math.h>
    
#include "Petrel.h"

Petrel::Petrel(double pc_, double rc_, Sex sex_, bool cohort_):
    pc(pc_), rc(rc_),
    energy(BASE_ENERGY),
    sex(sex_),
    alive(true),
    incubationDays(0), lastIncubationBout(0),
    incubationBouts(0), meanIncubationBout(0),
    foragingDistribution(FORAGING_MEAN, FORAGING_SD)
{
    // TODO how to start incubation of mates?
    if (sex == Sex::Female)
        state = DayState::Incubating;
    else
        state = DayState::Foraging;
}

void Petrel::petrelDay()
{    
    // decide if you're going to change state
    changeState();
    mate->changeState();
    
    checkOverlap();
    
    actState();
    mate->actState();
}

// bool Petrel::decideSurvival()
// {
//     // Estimates from results of weighted mean survival from (Mauck et al. 2012)
//     // for first winter after breeding, mean survival is 74.9%
//     // for second winter after breeding, mean survival is 80.2%
//     // for third winter onwards, mean survival is 87.0%
//     double survival;
//     if (age == 0)
//         survival = .749;
//     else if (age == 1)
//         survival = .802;
//     else
//         survival = .87;
    
//     double chance = static_cast<double>(rand()) / RAND_MAX;
//     if (chance > survival)
//         return false;   // dead petrel
    
//     return true;    // live petrel!
// }

void Petrel::changeState()
{
    switch (state) {
        // decide if you're going to stop foraging
        case DayState::Foraging :
            double chance = static_cast<double>(rand()) / RAND_MAX;
            if (chance <= stopForagingProb()) {
                state = DayState::Incubating;
                resetDays();
            }
            break;
        
        // decide if you're going to stop incubating
        case DayState::Incubating :
            double chance = static_cast<double>(rand()) / RAND_MAX;
            if (chance <= stopIncubatingProb()) {
                state = DayState::Foraging;
                lastIncubationBout = incubationDays;
                incubationBouts.push_back(lastIncubationBout);

                resetDays();
            }
            break;
    }
}

void Petrel::checkOverlap()
{
    // if both the petrels are incubating, make sure the appropriate one switches
    if (state == DayState::Incubating && mate->getState() == DayState::Incubating) {
        // switch whichever has been incubating longer back to foraging
        if (incubatingDays > mate->getIncubatingDays())
            state == DayState::Foraging;
        else if (incubatingDays < mate->getIncubatingDays())
            mate->setState(DayState::Foraging);
        
        // if they both just arrived, pick randomly
        else if (incubatingDays == mate->getIncubatingDays()) {
            double chance = static_cast<double>(rand()) / RAND_MAX;
            if (chance < .5)
                state == DayState::Foraging;
            else
                mate->setState(DayState::Foraging);
        }
    }
}

void Petrel::actState()
{
    // act according to your state
    switch (state) {
        case DayState::Foraging :
            forage();
            break;
        case DayState::Incubating :
            incubate();
            break;
    }
    // dead bird
    if (energy <= DEATH_ENERGY_THRESHOLD)
        alive = false;
}

void Petrel::forage()
{
    // uses a time-based seed to generate a random value from the random distribution 
    // created from foraging max and min values using time as a seed
    unsigned seed = std::chrono::system_clock::now().time_since_epoch().count();
    std::default_random_engine generator(seed);

    double foragingChange = foragingDistribution(generator);
    // cut off at the max and the min values, takes basically a parabola as an approximation of the
    // top perctile options from the normal curve (one standard deviation from the mean)
    // TODO fix the way this foraging value is created. It seems sillier, although more reasonable
    //      than a linear random number generator given the max and min values
    if (foragingChange < FORAGING_MIN)
        foragingChange = FORAGING_MIN;
    else if (foragingChange > FORAGING_MAX)
        foragingChange = FORAGING_MAX;

    energy += foragingChange;
}

void Petrel::incubate()
{
    // exceedingly trivial
    // TODO need to add any complexity to this behavior?
    energy -= INCUBATING_LOSS;
    incubatingDays++;
}

// TODO MAKE SURE THIS BEHAVIOR IS ON POINT, definitely should look for revisions
//      are there reasons for this to be adapted into a logistic model, increasing stochasticity
//          (but allowing for a broader range of probabilities?)
//      and the magnitudes to which RC and PC affect the decision
//      what should we think of as the BASELINE for mate information?
//          right now RC works in conjunction with the difference between the lastIncBout and the mean of all incBouts 
//          of course, that means the mean starts at 0 and has no effect if there's been no incubation
double Petrel::stopForagingProb()
{
    // See README for additional discussion
    // The probability of stopping foraging (P) is a simple threshold
    // Dependent on x, the current energy level,
    // which interacts positively with pc and negatively with the interaction of rc and the length of the last incubation bout (I)
    // these PC and RC values shift the threshold up and down the energetic axis
    // when foraging, you're more likely to stop foraging if you have high energy, so y->1 when x->inf

    // RC contribution
    double rcEffect = 0;
    if (lastIncubationBout >  meanIncubationBout && rc < 0) // retaliatory conditions
        rcEffect = (lastIncubationBout - meanIncubationBout) / meanIncubationBout * abs(rc) * BASE_ENERGY;
    else if (lastIncubationBout < meanIncubationBout && rc > 0) // compensatory conditions
        rcEffect = (lastIncubationBout - meanIncubationBout) / meanIncubationBout * rc * (BASE_ENERGY * -1);

    // PC contribution
    double pcEffect = BASE_ENERGY * PC;

    if (energy > (pcEffect + rcEffect))
        return 1.0;
    else
        return 0.0
}

// TODO DITTO
double Petrel::stopIncubatingProb()
{
    // This is the reflection.
    // When incubating, the less energy you have, the more likely you are to stop.
    // So this curve increases with the inverse of energy 1/E, where y->0 as x->inf

    // RC contribution
    double rcEffect = 0;
    if (lastIncubationBout >  meanIncubationBout && rc < 0) // retaliatory conditions
        rcEffect = (lastIncubationBout - meanIncubationBout) / meanIncubationBout * abs(rc) * BASE_ENERGY;
    else if (lastIncubationBout < meanIncubationBout && rc > 0) // compensatory conditions
        rcEffect = (lastIncubationBout - meanIncubationBout) / meanIncubationBout * rc * (BASE_ENERGY * -1);

    // PC contribution
    double pcEffect = BASE_ENERGY * PC;

    if (energy > (pcEffect + rcEffect))
        return 0;
    else
        return 1.0;
}

void Petrel::resetDays()
{
    foragingDays = 0;
    incubatingDays = 0;
}
