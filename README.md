Email: 	 liam.taylor@yale.edu
Twitter: @LUlyssesT
Website: ltaylor2.github.io

The main branch of this repository currently hosts the code version from the American Ornithological Society 2019 Conference in Anchorage, Alaska.

RUN INSTRUCTIONS
The C++ source code can be compiled in the Scripts/ directory with 'make".

Running the program with ./lhsp will simulate the models requested in main(), printing summary output to the Output/ directory for each behvioral parameter. 

Iterations and other important constants can be found at the top of main.cpp.

Figures for the AOS19AK poster can be generated using the R script Figures/lhsp_visualizations.r with the help of the tidyverse (TIDYVERSE link) packages.

ACKNOWLEDGMENTS
I would first like to thank the many scientists, artists, and students with whom I spent time at the Bowdoin Scientific Station on Kent Island, New Brunswick, Canada. My work there under Dr. Robert Mauck in the summers of 2014 and 2015 first inspired my interest in the complicated, . My thanks also to Dr. Nathaniel Wheelwright for serving as an inspiring and thoughtful ornithological advisor during my time at Bowdoin, and to Dr. Richard Prum for doing the same as I begin my career at Yale EEB. Thanks also to Dr. Alvaro Sanchez and Dr. Stephen Stearns for their careful critique and comments on two course projects which combined to form the bulk of the present model. Support for this project came in part from NSF (GRFP #DGE1752134) and the Coe fund.

PARAMETER SOURCES
All literature sources for empirical energetic parameters are cited within the code. Full reference information follows.

Boersma, P. D., and N. T. Wheelwright. 1979. Egg neglect in the Procellariiformes: reproductive adaptations in the Fork-tailed Storm-Petrel. Condor 81:157–165.

Montevecchi, W. A., I. R. Kirkham, D. D. Roby, and K. L. Brink. 1983. Size, organic composition, and energy content of Leach’s storm-petrel (Oceanodroma leucorhoa ) eggs with reference to position in the precocial–altricial spectrum and breeding ecology. Canadian Journal of Zoology 61:1457–1463.

Montevecchi, W. A., V. L. Birt-Friesen, and D. K. Cairns. 1992. Reproductive energetics and prey harvest of Leach’s storm-petrels in the northwest Atlantic. Ecology 73:823–832.

Pollet, I. L., R. A. Ronconi, I. D. Jonsen, M. L. Leonard, P. D. Taylor, and D. Shutler. 2014. Foraging movements of Leach’s storm-petrels Oceanodroma leucorhoa during incubation. Journal of Avian Biology 45:305–314.

Ricklefs, R. E. 1983. Some considerations on the reproductive energetics of pelagic seabirds. Studies in Avian Biology 8:84–94.

Ricklefs, R. E., D. D. Roby, and J. B. Williams. 1986. Daily Energy expenditure by Adult Leach’s Storm-Petrels during the Nesting Cycle. Physiological Zoology 59:649–660.

Ricklefs, R. E., S. C. White, and J. Cullen. 1980. Energetics of postnatal growth in Leach’s Storm-Petrel. The Auk 97:566–575.

Stephens, D. W., and E. L. Charnov. 1982. Optimal foraging: Some simple stochastic models. Behavioral Ecology and Sociobiology 10:251–263.

Zangmeister, J. L., M. F. Haussmann, J. Cerchiara, and R. A. Mauck. 2009. Incubation failure and nest abandonment by Leach’s Storm-Petrels detected using PIT tags and temperature loggers. Journal of Field Ornithology 80:373–379.
 
