#include <cstdlib>
#include <iostream>

#include "Egg.h"

Egg::Egg():
    alive(true), hatched(false),
    hatchDays(START_HATCH_DAYS),
    currDays(0),
    negCounter(0), maxNegCounter(0)
{}

void Egg::eggDay(bool incubated)
{
    if (incubated) {
        std::cout << "I'm an egg! I'm being incubated" << std::endl;
        negCounter = 0;    
    }
    else {
        negCounter++;
        if (negCounter > maxNegCounter)
            maxNegCounter = negCounter;
        hatchDays += NEGLECT_PENALTY;
        std::cout << "I'm an egg! I'm being neglected for " << negCounter << " days with the longest streak of "
                  << maxNegCounter << " days. My new hatch days is " << hatchDays << std::endl;
    }
    
    // if the egg has been incubated to catch up to the number of days required to hatch
    // check the survival based on the neglect patterns, and if it survived, hatch it
    if (currDays >= hatchDays) {
        alive = eggSurvival();
        hatched = alive;
    }
    
    // if the egg has been incubating for a very long time building
    // up neglect days, it's dead in any case
    if (currDays >= HATCH_DAYS_MAX) {
        std::cout << "I am an egg! I just died from incubation lasting too long" << std::endl;
        alive = false;
    }
    
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
    
    if (chance <= mortality) {
        std::cout << "I am an egg! I just died at hatch" << std::endl;
        return false;   // egg dies!
    }
    
    std::cout << "I am an egg! I just hatched succesfully" << std::endl;
    return true;    // egg survives!
}


        
    