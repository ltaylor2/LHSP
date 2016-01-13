#pragma once
    
enum class Sex { Male, Female };
enum class DayState { Incubating, Foraging };

class Petrel {
    
public:
    
    // Constructor
    // @params double pc_ = Physiological Condition Variable (for state changes based on health) 0-1;
    //         double rc_ = Reaction Condition Variable (for state changes based on mate behavior) -1-1;
    //         double energy_ = Starting energy for the new petrel
    //         Sex sex_ = Biological sex of the adult
    Petrel(double pc_, double rc_, Sex sex_, bool cohort);
    
    // Run through a day of incubation, or foraging, with associated state change
    // decision-making and energy changes
    void petrelDay();
    
    // Change the state of another bird
    void changeState();
    
    // Check if both are incubating
    void checkOverlap();
    
    // Act out the state you're in
    void actState();
        
    // Every year, decide whether or not the adult survives to the next breeding season
    bool decideSurvival();
    
    // Change the adult's age
    void setAge(int age_) { age = age_; }
        
    // Sets the focal adult's current mate, allowing passage of information between the adults
    // @params Petrel* mate = ptr to another adult
    void pairBond(Petrel* mate_) { mate = mate_; }
    
    // sets the energy to the base energy for the beginning of a new breeding year
    void resetEnergy() { energy = BASE_ENERGY; }
    
    // Getters
    int getAge() { return age; }
    double getPC() { return pc; }
    double getRC() { return rc; }
    double getEnergy() { return energy; }
    DayState getState() { return state; }
    DayState getIncubatingDays() { return incubatingDays; }
    bool isAlive() { return alive; }
    Petrel* getMate() { return mate; }
    Sex getSex() { return sex; }

private:
    // Initial petrel energy, 766kJ at the beginning of an incubation season (Ricklefs et al 1986)
    const static double BASE_ENERGY = 766;
    
    // When you're a dead petrel TODO right number??
    const static double DEATH_ENERGY_THRESHOLD = 0.0;
    
    // Energy loss from incubation, 51.5kJ/day (Ricklefs et al 1986), (Blackmer et al 2005) closely agrees
    const static double INCUBATING_LOSS = 51.5;

    // using the equations from (Montevecchi et al 1992) for FMR and ME
    // where ME(+) kJ/day = (48.8 +- 48.0) + (6.62 +- 2.73) * x hrs/day
    // and where FMR(-) kJ/day = (85.8 +- 6.5) + (3.13 +- 0.48) * x hrs/day 
    // thus max = max(ME) - min(FMR) using SD's and 24 hrs = 321.2 - 142.9 = 178.3
    // and  min = min(ME) - max(FMR) using SD's and 24 hrs = 94.16 - 178.94 = -84.94
    const static double FORAGING_MAX = 178.3;
    const static double FORAGING_MIN = -84.94;
    
    // changing energy based on the current state
    void forage();
    void incubate();
    
    // reset the counters for days
    void resetDays();
    
    // chance that you will stop foraging, based on PC and RC
    double stopForagingProb();
    
    // chance that you will stop foraging, based on PC and RC
    double stopIncubatingProb();
    
    
    Petrel* mate;
    
    int age;
    double pc;
    double rc;
    double energy;
    Sex sex;
    DayState state;
    bool alive;
    bool cohort;
    int foragingDays;
    int incubatingDays;
    int lastIncubationBout;
};
    
    
    
        
    
    
        
    
    
    