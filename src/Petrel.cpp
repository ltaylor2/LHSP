#include <stdlib>
#include <math.h>
    
#include "Petrel.h"

Petrel::Petrel(double pc_, double rc_, Sex sex_, bool cohort_):
    age(0), pc(pc_), rc(rc_),
    energy(BASE_ENERGY),
    sex(sex_), state(DayState::Incubating),
    alive(true),
    foragingDays(0), incubationDays(0), lastIncubationBout(0)
{}

void Petrel::petrelDay()
{    
    // decide if you're going to change state
    changeState();
    mate->changeState();
    
    checkOverlap();
    
    actState();
    mate->actState();
}

bool Petrel::decideSurvival()
{
    // Estimates from results of weighted mean survival from (Mauck et al. 2012)
    // for first winter after breeding, mean survival is 74.9%
    // for second winter after breeding, mean survival is 80.2%
    // for third winter onwards, mean survival is 87.0%
    double survival;
    if (age == 0)
        survival = .749;
    else if (age == 1)
        survival = .802;
    else
        survival = .87;
    
    double chance = static_cast<double>(rand()) / RAND_MAX;
    if (chance > survival)
        return false;   // dead petrel
    
    return true;    // live petrel!
}

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
    energy += static_cast<double>(rand()) / RAND_MAX * (FORAGING_MAX - FORAGING_MIN) + FORAGING_MIN;
    foragingDays++;
}

void Petrel::incubate()
{
    energy -= INCUBATING_LOSS;
    incubatingDays++;
}

// TODO FIGURE OUT THIS BEHAVIOR, IT'S THE ACTUALLY IMPORTANT PART! ESP MIDPOINT X0 
double Petrel::stopForagingProb()
{
    // The probability of stopping foraging (P) is a logistic curve with a maximum of 1 and a minimum of 0
    // Dependent on x, the current energy level
    // Which interacts positively with pc and negatively with the interaction of rc and the length of the last incubation bout (I)
    // when foraging, you're more likely to stop foraging if you have high energy, so y->1 when x->inf
    // P = 1 / [1 + e^-((pc + I * -rc) / 10)(E - BASE_E)]
      double x = -((pc * lastIncubationBout * rc / 10) * (energy - BASE_ENERGY);
    return 1 / (1 + exp(x));
}

// TODO DITTO, ESPECIALLY WITH REFLECTION
double Petrel::stopIncubatingProb()
{
    // This is the opposite. When incubating, the less energy you have, the more likely you are to stop. So this curve increases with the inverse of energy 1/E
    double x = -((pc * lastIncubationBout * rc / 10) * (-energy - BASE_ENERGY);
    return 1 / (1 + exp(x));
}

void Petrel::resetDays()
{
    foragingDays = 0;
    incubatingDays = 0;
}
