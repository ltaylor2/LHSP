#include <cstdio>
#include <cstdlib>
#include <ctime>
#include <iostream>
#include <fstream>

#include "Petrel.h"
#include "Egg.h"

// breeds a focal petrel with its mate and an egg for an incubation season
bool breedingSeason(Petrel &petrel, Egg egg);

// 71% of failed hatches switch burrows (Mauck 1997)
// 74% of switched burrows switch mates (Blackmer et al 2004)
// .71 * .74 = .54
// static const double MATE_SWITCH_CHANCE = 0.54;

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
    
    for (double p = 0; p <= .25; p += .05) {           // run 0-1 PC by .25, and -1-1 RC by .5
        std::cout << "Male PC = " << p << std::endl;
        for (double r = -1; r <= 1; r += .5) {
            std::cout << "Male RC = " << r << std::endl;
            Petrel mPetrel(p, r, Sex::Male);
            for (double fp = 0; fp <= .25; fp += .05) {        // for all combinations of mates
                for (double fr = -1; fr <= 1; fr += .5) {
                    Petrel fPetrel(fp, fr, Sex::Female);
                    mPetrel.setMate(&fPetrel);

                    int totalSuccess = 0;
                    int sampleSize = 5000;
                    for (int i = 0; i < sampleSize; i++) {      // for 500 replicates
                        Egg egg = Egg();    // TODO not compiling as Egg egg();?? c++ rvalue error to fix
                        if (breedingSeason(mPetrel, egg))
                            totalSuccess++;
                    }

                    File << mPetrel.getPC() << "," << mPetrel.getRC() << ","
                         << fPetrel.getPC() << "," << fPetrel.getRC() << ","
                         << static_cast<double>(totalSuccess) / sampleSize << std::endl;
                }
            }
        }
    }
    
    std::cout << "Breeding Done!" << std::endl; 
    File.close();
    
    return 0;
}
              
bool breedingSeason(Petrel &petrel, Egg egg)
{
    // start afresh
    petrel.reset();
    petrel.getMate()->reset();
    
    // apply initial egg-laying cost
    if (petrel.getSex() == Sex::Female)
        petrel.setEnergy(petrel.getEnergy() * (1 - EGG_ENERGY_COST));
    else
        petrel.getMate()->setEnergy(petrel.getMate()->getEnergy() * (1 - EGG_ENERGY_COST));
        
    // Ends on four conditions:
    //  1. egg hatches alive (success)
    //  2. egg dies at hatch (failure)
    //  3. parent 1 dies (failure)
    //  4. parent 2 dies (failure)
    while (egg.isAlive() && !egg.isHatched()
           && petrel.isAlive() && petrel.getMate()->isAlive()) {
        // run through both parents' activities for a day, called through just one parent
        petrel.petrelDay();
                
        // decide egg behavior
        bool incubated = false;
        if (petrel.getState() == DayState::Incubating
            || petrel.getMate()->getState() == DayState::Incubating)
            incubated = true;
        egg.eggDay(incubated);
    }

    // report the output, returning true if the parent succesffully incubated
    if (egg.isHatched() && egg.isAlive())
        return true;

    return false;
}
