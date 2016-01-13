#pragma once

class Egg {

public:
    // Constructor
    Egg();

    // Is the egg getting incubated or not?
    // @params bool incubated = is an adult sitting on the egg for a day?
    void eggDay(bool incubated);
    
    // Return maximum neglect, to determine how long incubation will have to last
    int getMaxNeg() { return maxNegCounter; }
    
    bool isAlive() { return alive; }
    bool isHatched() { return hatched; }
    
private:
    // Minimum observed incubation period (Huntington et al 1996)
    constexpr static double START_HATCH_DAYS = 37.0;
    
    // a very high number, for when you know the egg would not hatch
    constexpr static double HATCH_DAYS_MAX = 80;
        
    // (Boersma and Wheelwright 1979) fit a line for Fork-Tailed storm-petrels.
    // with a slope of .7 for (days incubation) ~ (days neglect) 
    // Thus, each day of neglect should increase the number of days required for hatch by .7
    // TODO DECREASE COEFFICIENT TO ADJUST FOR SHORTER LHSP INCUBATION VS FTSP?
    constexpr static double NEGLECT_PENALTY = .7;
    
    // Tiers of neglect (max days continuously neglected) correlating to early chick death in FTSP (Boersma and Wheelwright 1979)
    // TODO get better data on this! check the database??
    constexpr static double T0_NEGLECT = 8;
    constexpr static double T0_MORTALITY = 0;
    
    constexpr static double T1_NEGLECT = 11;
    constexpr static double T1_MORTALITY = .26;
    
    constexpr static double T2_MORTALITY = .43;
    
    // determine if an egg has survived with the given level of neglect
    bool eggSurvival();
        
    bool alive;     // is it alive?
    bool hatched;   // is it hatched?
    
    // counters for required and current incubation days
    double hatchDays;
    double currDays;
    
    // what is the current neglect streak? (days)
    int negCounter;
 
    // what is the maximum neglect streak? (days)
    int maxNegCounter;
};
    
    
