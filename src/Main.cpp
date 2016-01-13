#include <stdio>
#include <stdlib>
#include <time>
#include <iostream>
#include <fstream>

#include "Petrel.h"
#include "Egg.h"

// TODO Method prototypes
//      FILE OUTPUT
//      R FEED
//      MODEL DISTRIBUTION
//      Testing fitness with all strategies, or against a pop that could abuse any strategy?
    
// gives a focal petrel a new mate
void newMate(Petrel &focal);

// breeds a focal petrel with its mate and an egg for an incubation season
void breedingSeason(Petrel &focal, Egg &egg);

// 71% of failed hatches switch burrows (Mauck 1997)
// 74% of switched burrows switch mates (Blackmer et al 2004)
// .71 * .74 = .54
static const double MATE_SWITCH_CHANCE = 0.54;

// Energetic cost of laying an egg as a female
// 20% of a female's body mass, here represented as energy (Bond and Hobson 2015) & (Bond and Diamond 2010)
// TODO CONSIDER (Motevecchi et al 1983) 60.7kJ RAW ENERGY EGG COST INSTEAD
static const double EGG_ENERGY_COST = .2;

int main(int argc, char* argv[])
{
    // seed random for num generator
    srand(time(NULL));
          
    std::ofstream File;
    File.open("Results.txt");
    
    std::cout << "Starting petrel breeding!" << std::endl;
    
    for (double p = 0; p <= 1; p += .1) {           // run 0-1 PC by .1, and -1-1 RC by .2
        for (double r = -1; r <= 1; r += .2) {
            for (int s = 0; s < 2; s++) {           // for each sex
                Sex sex;
                if (s == 0)
                    sex = Sex::Male;
                else
                    sex = Sex::Female;
                for (int i = 0; i < 50; i++) {      // for 50 trials 
                    // produce focal petrel and set initial mate
                    Petrel fPetrel(p, r, sex);
                    newMate(fPetrel);
          
                    // Run every breeding year as long as petrel is alive between seasons
                    do {
                        Egg egg();
                        breedingSeason(fPetrel, egg);   
                
                        // decide whether to keep a new mate or produce another one
                        if (fPetrel.getMate()->isAlive() && fPetrel.getMate()->decidedSurvival()) {
                            if (!egg.isHatched()) {
                                double chance = static_cast<double>(rand()) / RAND_MAX;
                
                                if (chance <= MATE_SWITCH_CHANCE) {
                                    newMate(fPetrel);
                                }
                            }       
                        } else
                            newMate(fPetrel);
                        
                        if (egg.isHatched())
                            File << r << p << std::endl;
        
                    } while(fPetrel.decideSurvival());
                }
            }
        }
    }
    
    std::cout << "Breeding Done!" << std::endl;
    
    File.close();
    
    return 0;
}

void newMate(Petrel &focal)
{
    // produce random values for pc, rc
    double pc = static_cast<double>(rand()) / RAND_MAX;
    double rc = static_cast<double>(rand()) / RAND_MAX * 2 - 1;
    
    Sex mSex;
    if (focal.getSex() == Sex::Male)
        mSex = Sex::Female;
    else
        mSex = Sex::Male;
    
    Petrel mPetrel(pc, rc, mSex);
    focal.pairBond(&mPetrel);
}
              
void breedingSeason(Petrel &focal, Egg &egg)
{
    fPetrel.resetEnergy();
    fPetrel.getMate()->resetEnergy();
    
    // apply initial egg-laying cost
    if (fPetrel.getSex() == Sex::Female)
        fPetrel.setEnergy(fPetrel.getEnergy() * (1 - EGG_ENERGY_COST));
    else
        fPetrel.getMate()->setEnergy(fPetrel.getMate()->getEnergy() * (1 - EGG_ENERGY_COST));
        
    // run through the season
    bool breedSuccess = false;
    while (egg.isAlive() && !egg.isHatched() && fPetrel.isAlive()) {
        // run through both parent's activities for a day, called through just one parent
        fPetrel.petrelDay();
                
        // decide egg behavior
        bool incubated = false;
        if (fPetrel.getState() == DayState::Incubating
            || fPetrel.getMate()->getState() == DayState::Incubating)
            incubated = true;
        egg.eggDay(incubated);
    }
    
    // age both parents
    fPetrel.setAge(fPetrel.getAge() + 1);
    fPetrel.getMate()->setAge(fPetrel.getMate()->getAge() + 1);
}
