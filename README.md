
<p>
<strong>Email</strong>: 	   l.taylor@bowdoin.edu<br>
<strong>Bluesky</strong>:   @liamtaylor.bsky.social<br>
<strong>Website</strong>:   https://ltaylor.mmm.page/<br>
<br>
Computational model system for analyzing the behavior and reproduction of seabird pair-bonds. Currently hosts code analyzing the energetics and schedules of two storm-petrel parents and an egg across the incubation season. Currently parameterized for Leach's Storm-Petrels (<i>Hydrobates leucorhous</i>) in the northwest Atlantic.
</p>

---

<h3>Instructions</h3>
<p>
The C++ source code can be compiled in the <code>Scripts/</code> directory with <code>make</code>.
<br><br>
In the <code>src/</code> directory, run the compiled program with <code>./lhsp</code>. Simulation output (big file) is written to Output/ directory. 
<br><br>
An example slurm script (for running simulations on HPC) is provided in <code>lhsp.sh</code>.
<br><br>
Process the simulation output file with <code>R/process_simulation_results.r</code>. Processed output data is written as a separate file (<code>Output/processed_results.csv</code>).
<br><br>
Analyze processed results with <code>R/analysis.r</code>. Descriptive statistics are logged in <code>Output/</code>, while plot images are saved to <code>Plots</code>.
<br><br>
Iteration settings, parameter test vectors, and other important settings can be found at the top of <code>src/main.cpp</code>.
<br>