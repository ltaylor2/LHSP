# LHSP Sandbox — Browser-Side Seabird Pair-Bond Simulation

Interactive port of Liam Taylor's
[Leach's Storm-Petrel (LHSP) incubation model](https://github.com/ltaylor2/LHSP/tree/schedule_manuscript)
running entirely in the browser.

The original C++ model is reimplemented in vanilla JavaScript
(`js/model.js`), so each browser tab runs its own simulations locally —
no backend, no database, no per-user state on a server. Open as many tabs
across as many computers as you like; they don't share state.

## What's in here

```
seabird-modeling/
├── index.html
├── style.css
├── js/
│   ├── model.js              the simulation port (Egg, Parent, season loop)
│   ├── sim.js                chunking + abort-aware sweep helpers
│   ├── app.js                tab navigation
│   └── tabs/
│       ├── replay.js         Kent-Island colony replay (canvas pixel art)
│       ├── heatmap.js        live (hunger × satiation) heatmap
│       ├── strips.js         100 seasons rendered as F/M/N stripes
│       ├── phase.js          (E_F, E_M) phase portrait
│       ├── tornado.js        one-at-a-time sensitivity
│       └── pareto.js         hatch-vs-survival Pareto front
└── notes/
    ├── lhsp_model_analysis.md      original code summary
    └── analytical_models.md         ODE/SDE/IG/Markov derivations
```

## The six tabs

1. **Colony replay** — top-down pixel-art map of Kent Island with up to 60
   breeding pairs. Each pair has a randomly-placed burrow on the island and
   two storm petrels (♀ tan, ♂ slate, both with the white rump patch
   characteristic of LHSP). Watch shifts emerge: parents fly out to sea,
   wander, and return to switch with their partner. Below the map: live
   colony averages (mean energies, % of pairs currently attended,
   cumulative outcomes) and a stacked-state coverage ribbon.

2. **Parameter heatmap** — a (hunger × satiation) grid recoloured by hatch
   rate / parent survival / mean hatch days / mean max neglect.
   **Sliders update the heatmap live** (debounced ~220 ms, cancellable).
   Click a cell to jump to *Season strips* with that combo loaded.

3. **Season strips** — N replicate seasons drawn as stacked F/M/N stripes,
   sortable by outcome / hatch length / total neglect. Live-updating.

4. **Phase portrait** — energy trajectories in the (♀-energy, ♂-energy)
   plane, one polyline per season, coloured by outcome. Threshold
   reference lines update as the relevant sliders move. Live-updating.

5. **Sensitivity tornado** — baseline at field defaults; each parameter is
   perturbed ±X%, bars sorted by impact on hatch rate. Live-updating.

6. **Pareto front** — every (hunger × satiation) combo plotted as
   (hatch rate, parent-survival rate); non-dominated combos are
   highlighted as the Pareto frontier. Live-updating.

## Running locally

There is no build step. Any static HTTP server will do:

```bash
cd seabird-modeling
python3 -m http.server 8765
# open http://127.0.0.1:8765
```

Or with Node:

```bash
npx http-server -p 8765
```

## How concurrency works

All simulation runs in the visiting browser. There is no shared state
between users:

* No backend, no database, no cookies.
* Sliders / outputs / plots live in the page DOM only.
* Each tab page has its own JS context — sweeps, plots, animation are all
  per-tab memory.
* In-flight sweeps are cancelled (via `AbortSignal`) the moment any slider
  changes again, so dragging a slider across many values doesn't pile up.
* URL hash (`#replay`, `#heatmap`, …) deep-links to a tab and round-trips
  through `hashchange`, so a shared link opens that tab directly.

If you want to host this for a class or workshop, drop the folder behind
any static file server (S3, GitHub Pages, Netlify, nginx) — no environment
variables, no secrets.

## Mapping back to the C++

| C++ symbol | JS equivalent |
|---|---|
| `Egg::EGG_COST`              | `Constants.EGG_COST` (69.7 kJ) |
| `Egg::HATCH_DAYS`            | `Constants.START_HATCH_DAYS` (37) |
| `Egg::NEGLECT_PENALTY`       | `Constants.NEGLECT_PENALTY` (1.43) |
| `Egg::neglectMax`            | `params.eggTolerance` |
| `Parent::BASE_ENERGY`        | `Constants.BASE_ENERGY` (766 kJ) |
| `Parent::INCUBATING_METABOLISM` | `Constants.INCUBATING_METABOLISM` (52) |
| `Parent::FORAGING_METABOLISM`   | `Constants.FORAGING_METABOLISM` (123) |
| `Parent::stopIncubating()`   | inline `energy <= minThresh` check |
| `Parent::stopForaging()`     | inline `energy >= maxThresh && foragingDays > 1` check |
| return-overlap rule          | resolved via `previousDayState` after both `parentDay()` calls |

`runSeason(params, seedOrRng)` returns a single season; `runReplicates(params,
n, seed0)` aggregates statistics across `n` reproducible replicates.

## Reading

* `notes/lhsp_model_analysis.md` — annotated walkthrough of the upstream C++.
* `notes/analytical_models.md` — closed-form companions: piecewise ODE,
  inverse-Gaussian first-passage time for foraging shifts, pair-state
  Markov chain, renewal-reward egg accumulation, Fokker–Planck for the
  whole colony, and an MDP framing of the threshold-optimisation problem.
  Useful when you want to predict the simulator's output instead of running
  it, or to understand which parameters fundamentally drive the dynamics.

## License

Same as the upstream LHSP repository (CC-BY 4.0 for code/data per its README).
