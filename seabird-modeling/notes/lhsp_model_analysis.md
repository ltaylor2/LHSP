# LHSP model — what the code actually does

Reference: [ltaylor2/LHSP @ schedule_manuscript](https://github.com/ltaylor2/LHSP/tree/schedule_manuscript)

## Scope of this note
A working understanding of every moving piece in Liam Taylor's Leach's
Storm-Petrel (LHSP) incubation model, from C++ source to manuscript-level
biology, so we can decide what to visualize and what to rebuild.

## Components

### `src/Egg.hpp` / `Egg.cpp`
A single egg with a hatching countdown.
* `START_HATCH_DAYS = 37` — the minimum incubation period.
* `HATCH_DAYS_MAX = 60` — hard cutoff (breeding window ends).
* `EGG_COST = 69.7 kJ` — energy the female pays at the start of the season.
* `NEGLECT_PENALTY = 1.43` — every day of neglect adds 1.43 days to the
  required hatch time (calibrated from Wheelwright & Boersma 1979 for
  Fork-tailed Storm-Petrels: their fit was 0.7 days of incubation per day
  of neglect, so the inverse 1/0.7 ≈ 1.43 lengthens the requirement).
* `NEGLECT_MAX = 7` — if the egg is left unincubated for 7 *consecutive*
  days it dies.
* Each day, `eggDay(incubated)` either resets the consecutive-neglect
  counter (if a parent is on the egg) or extends `hatchDays` by 1.43 and
  bumps the neglect streak.
* The egg hatches when `currDays >= hatchDays`.

### `src/Parent.hpp` / `Parent.cpp`
A breeding adult with three states (`incubating`, `foraging`, `dead`).
Constants are calibrated from real Newfoundland LHSP data
(Montevecchi et al. 1992, Ricklefs et al. 1986):
* `BASE_ENERGY = 766 kJ` (starting buffer).
* `INCUBATING_METABOLISM = 52 kJ/day`.
* `FORAGING_METABOLISM = 123 kJ/day` — flying out to feed is more than 2×
  more expensive than sitting on the egg.
* `FORAGING_MEAN = 162 kJ/day`, `FORAGING_SD = 47 kJ/day` — daily intake
  is drawn from `N(mean, sd)`, clipped at 0.
* Females start incubating, males start foraging (matches field
  observations of who stays for the first bout).

The state machine, evaluated each day in `parentDay()`:
1. Record current energy.
2. If `energy <= 0` → `dead`.
3. If incubating → subtract 52 kJ. If `energy <= minEnergyThresh`
   (hunger threshold) → switch to foraging at end of day.
4. If foraging → subtract 123 kJ, add `~ N(foragingMean, foragingSD)` kJ.
   If `energy >= maxEnergyThresh` (satiation threshold) AND has been
   foraging > 1 day → switch to incubating.

Each parent therefore behaves like a thermostat with two knobs the
manuscript explores:
* **Hunger threshold** (`minEnergyThresh`) — how empty does my tank have
  to get before I abandon the egg?
* **Satiation threshold** (`maxEnergyThresh`) — how full do I have to be
  before I'll come back to the egg?

### `src/main.cpp` — the breeding-season loop
For each parameter combination and each replicate, builds two parents and
one egg, then iterates day by day until the egg hatches, the egg dies, or
the breeding window expires:

```
while egg is alive AND not hatched AND age <= 60 days:
    eggDay(was anyone incubating?)
    pf.parentDay()
    pm.parentDay()
    if either parent died → break
    if both parents now incubating (rare overlap):
        whichever just returned takes over; the other leaves
        if both returned simultaneously, pick one at random
    record one of {F, M, N} for that day  (F=female on egg, M=male on egg, N=neither)
```

This is the entire pair-bond mechanism: there's no communication between
the birds — they only interact through the egg. A switchover happens
when a foraging bird's energy hits its satiation threshold and flies back
home; the bird already on the egg is freed to leave only because *both*
are now on the egg.

### Two parameter sweeps (`runModel` and `runModel_eggTolerance`)
The C++ binary runs nested grid searches (default 100 reps each):
* **Sweep 1 (energy thresholds + foraging environment):**
  * `minEnergyThresh ∈ {200, 300, …, 1100}` (10 values)
  * `maxEnergyThresh ∈ {400, 500, …, 1200}` (9 values)
  * Both swept independently for the female and the male.
  * `foragingMean ∈ {130, 140, …, 170}` (5 values) plus the field value 162.
  * `foragingSD ∈ {0, 10, …, 100}` (11 values) plus 47.
  * Combinations where hunger ≥ satiation are skipped.
* **Sweep 2 (egg tolerance):** narrower energy grid, foraging SD fixed,
  but adds an `egg tolerance ∈ {1, …, 7}` knob — i.e. how many consecutive
  days of neglect can the egg survive before dying. Calibrated from
  observed maxima in Fork-tailed Storm-Petrels.

For each (parameters × replicate), one row is written to a CSV: hatch
result, hatch date, total/max neglect, end/mean/var energy for each
parent, dead flags, season length, and the full `F`/`M`/`N` season history
string.

### `R/` — analysis & figures
`R/process_simulation_results.r` rolls up the per-day season-history
strings into bout-level summaries. `R/analysis.r` produces the manuscript
plots in `Plots/` and `Figures/`.

## What the manuscript is asking, in plain English

The biological puzzle: storm-petrel parents go on multi-day foraging
trips far out to sea, and their unattended chick / egg survives long
periods of neglect. Field biologists see that real parents seem to take
fairly long incubation bouts and tolerate quite a bit of neglect.

The simulation asks **what set of behavioral rules and environmental
conditions actually keeps the egg alive and the parents alive** — and
which combinations end in catastrophic failure. Concretely:
* Are the observed Newfoundland mean foraging intakes (162 ± 47 kJ/day)
  enough to support a successful pair-bond if the parents apply
  reasonable hunger/satiation rules?
* How robust is success to variability in foraging conditions
  (raise the SD)?
* How much neglect can the egg take before its tolerance becomes the
  bottleneck rather than the parents' energy budget?
* Does the (asymmetric) starting condition — female on the egg, male
  away — matter, or do the rules dominate?

The way the model produces emergent shift-changes from purely
energy-driven decisions is itself the main result: pair-bond coordination
*doesn't need communication*, just two birds with thermostats and an
egg that punishes long absences.

---

## Visualization & simulation opportunities

### Tier 1 — high-leverage, fits the existing data
1. **Single-season replay (the headline visual).** A daily animation
   showing two storm-petrel parents (each with an energy gauge), an egg
   in a burrow with a hatch-progress bar and a neglect-streak indicator,
   and a timeline ribbon at the bottom that fills in F/M/N as the season
   plays out. The user picks parameters with sliders and presses play.
   This is the visualization most likely to make a reader *feel* the
   shift-change dynamic the way the manuscript describes it.
2. **Parameter sweep heatmap.** 2D heatmap of hatch-success rate across
   `(minEnergyThresh, maxEnergyThresh)`, with sliders for foraging
   mean/SD and egg tolerance, and a "click a cell to see 100 example
   seasons" drilldown. The published figures already make a static
   version of this; an interactive one would let readers explore.
3. **Season-history strip chart.** All 100 replicates of one parameter
   cell as horizontal stripes coloured F/M/N, sorted by outcome. The
   user immediately sees which schedule patterns lead to hatch.

### Tier 2 — analytical follow-ups
4. **Phase portrait.** Plot 100 (femaleEnergy, maleEnergy) trajectories
   over the season as 2D paths colored by outcome. Successful seasons
   trace circular orbits; failed ones spiral inward.
5. **Sensitivity tornado.** Bar chart of how much hatch-success rate
   changes when each parameter is perturbed ±10% from the field value,
   ranked by effect size. Cheap to compute, very legible.
6. **Pareto front: hatch success vs parent survival.** Each point is one
   parameter combo; you see immediately whether reducing hunger threshold
   (taking longer bouts) trades parent risk for egg success.

### Tier 3 — speculative extensions
7. **Live sandbox where you change the rules, not just the parameters.**
   E.g. add a probabilistic "communication" channel where one bird is
   X% likely to predict its partner's return. Does coordination beat
   coupled thermostats? The current code has no communication, so this
   would need a small fork.
8. **Climate-shift slider.** Sweep `foragingMean` downward to simulate
   prey decline; show how the success-region in the heatmap shrinks
   year over year.
9. **Cluster the F/M/N season strings as motifs.** k-mer or Markov
   transition matrices to extract behavioral "regimes" (e.g.
   long-bout-shifters vs short-bout-shifters) and see which regimes
   dominate the high-success region.

### Recommendation for first build
Tier 1 #1 (single-season replay) plus Tier 1 #2 (interactive sweep
heatmap) gives a reader the full ladder: one for intuition, one for
exploration. Both are achievable with the existing CSV output plus a
small browser-side simulator (or a port of the C++ day-loop to TS/Python
for live runs).
