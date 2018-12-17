**Simple coordination in an avian incubation system**

Liam U. Taylor

Project/Code/Report for EEB_678

----------------------

**Abstract**
Leach’s Storm-petrels (Aves: Procellariiformes, Oceanodroma leucorhoa) are biparental breeders, with parents of both sexes working to incubate a single egg in a burrow located hundreds of kilometers away from their foraging grounds. Here, I develop a set of empirically-parameterized models to investigate the mechanisms by which two Leach’s Storm-petrel adults can coordinate their own energetic demands in addition to the developmental demands of their egg. I find that a simple “no overlap” condition (with either orderly or random swapping) increases hatching success from 11.1% to a near-perfect 99.8%. This simple rule also improves the developmental condition of the egg and the energetic outcomes of adults throughout the season. Further, I find that the energetic cost of the egg to females has minimal impact on incubation outcomes, suggesting other constraints on the clutch size of this species. Finally, the model is revealed to be critically sensitive to the mean (but not the variance) in normally-distributed foraging outcomes. Although a more complicated coordination strategy is not necessary given only the incubation dynamics presented here, incorporating multiple breeding seasons and the additional constraints of chick rearing/brooding may reveal the ways in which long-lived Leach’s Storm-petrels adaptively reduce their hatching success rate through dynamic scheduling behaviors that ultimately maximize lifetime reproductive success.

----------------------

**Data/** contains a single old data file with the PIT data represented in the paper.

**Docs/** contains copies of both the project proposal and final report

**Output/** contains figures from the report, and is also the directory to which model output is printed

**Scripts/** contains all of the new R and C++ code for running the 2018 model

**Scripts/Old_src/** contains the ancient (and disasterous, and bug filled) code from when I first though about these dynamics, as well as a report I wrote at the end of 2016 (my junior year in college!). It's interesting to see how similar the code ended up being (mostly because I parasitized the structure). Luckily, now the thing actually works and I can start asking some more interesting questions.

----------------------

**To Run**

The entire program can be run through R, interfacing with C++ using the Rcpp package. Take a look at Scripts/LHSP.r

No C++ objects are actually inherited into R after calling main() in R. The main() function will write all relevant output to files in the Output/ direction, which are then read-in and manipulated again in R. 

**NOTE** The important run-time variables (such as #Iterations and output filenames) are all written as global constants at the top of Scripts/main.cpp. I'll fix this as soon as Rcpp fixes compiling array function parameters.  
