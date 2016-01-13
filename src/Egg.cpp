#include <cstdlib>

#include "Egg.h"

Egg::Egg():
    alive(true), hatched(false),
    hatchDays(START_HATCH_DAYS),
    currDays(0),
    negCounter(0), maxNegCounter(0)
{}

void Egg::eggDay(bool incubated)
{
    if (incubated)
        negCounter = 0;    
    else {
        negCounter++;
        if (negCounter > maxNegCounter)
            maxNegCounter = negCounter;
        
        hatchDays += NEGLECT_PENALTY;
    }
    
    // if the egg has been incubated to catch up to the number of days required to hatch
    // check the survival based on the neglect patterns, and if it survived, hatch it
    if (currDays >= hatchDays) {
        alive = eggSurvival();
        hatched = alive;
    }
    
    // if the egg has been incubating for a very long time building
    // up neglect days, it's dead in any case
    if (currDays >= HATCH_DAYS_MAX)
        alive = false;
    
    // next day!
    currDays++;
}

bool Egg::eggSurvival()
{
    double mortality;
    if (maxNegCounter <= T0_NEGLECT)
        mortality = T0_MORTALITY;
    else if (maxNegCounter <= T1_NEGLECT)
        mortality = T1_MORTALITY;
    else
        mortality = T2_MORTALITY;
    
    // assumes random is seeded (do it in main()!)
    double chance = static_cast<double>(rand()) / RAND_MAX;
    
    if (chance <= mortality)
        return false;   // egg dies!
    
    return true;    // egg survives!
}


        
    