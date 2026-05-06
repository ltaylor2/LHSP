// model.js — port of Liam Taylor's LHSP incubation model.
//
// Source: https://github.com/ltaylor2/LHSP/tree/schedule_manuscript (src/*.cpp)
//
// Behaviour matches the C++ reference:
//   • Two parents (female starts incubating, male starts foraging)
//   • Each day each parent: subtract metabolism, possibly draw foraging intake,
//     possibly cross a hunger or satiation threshold and flip state.
//   • Egg gets a hatch-progress counter and a consecutive-neglect counter;
//     7 consecutive days of neglect is fatal; each neglect day adds 1.43 to
//     the hatch requirement.
//   • If both birds end the day on the egg, whoever was *foraging yesterday*
//     just got back, so the other one leaves. If both transitioned the same
//     day, a coin flip decides.
//
// The simulation is a pure function: same params + same rng seed → same
// season output. Safe to call from a Web Worker.

export const Constants = Object.freeze({
    EGG_COST: 69.7,
    START_HATCH_DAYS: 37,
    HATCH_DAYS_MAX: 60,
    NEGLECT_PENALTY: 1.43,
    DEFAULT_NEGLECT_MAX: 7,
    BASE_ENERGY: 766,
    INCUBATING_METABOLISM: 52,
    FORAGING_METABOLISM: 123,
    FORAGING_MEAN: 162,
    FORAGING_SD: 47,
});

// Field-derived defaults in the manuscript's swept range.
// (Pure C++ defaults are min=123, max=766; the sweep walks 200..1100 / 400..1200,
//  so 200/900 sits in the middle of the manuscript's exploration.)
export const DEFAULT_PARAMS = Object.freeze({
    minThresh_F: 200,
    maxThresh_F: 900,
    minThresh_M: 200,
    maxThresh_M: 900,
    foragingMean: 162,
    foragingSD: 47,
    eggTolerance: 7,
});

// ─── Outcome categories ────────────────────────────────────────────────────
export const OUTCOMES = Object.freeze({
    HATCHED:     'hatched',
    EGG_DIED:    'egg_died',
    FEMALE_DIED: 'female_died',
    MALE_DIED:   'male_died',
    BOTH_DIED:   'both_died',
    TIMEOUT:     'timeout',
});

export const OUTCOME_COLOURS = Object.freeze({
    hatched:     '#2ecc71',
    egg_died:    '#e84a4a',
    female_died: '#c084fc',
    male_died:   '#0ea5e9',
    both_died:   '#7f1d1d',
    timeout:     '#9aa6b2',
});

// ─── RNG helpers ────────────────────────────────────────────────────────────
// Deterministic mulberry32 so a "seed" makes the same season reproducible
// across browsers / tabs. If no seed is given, we wrap Math.random so callers
// get a non-deterministic stream.
export function makeRng(seed) {
    if (seed === undefined || seed === null || seed === '') {
        return Math.random;
    }
    let t = (typeof seed === 'string' ? hashStr(seed) : Math.floor(seed)) >>> 0;
    return function () {
        t = (t + 0x6D2B79F5) >>> 0;
        let r = t;
        r = Math.imul(r ^ (r >>> 15), r | 1);
        r ^= r + Math.imul(r ^ (r >>> 7), r | 61);
        return ((r ^ (r >>> 14)) >>> 0) / 4294967296;
    };
}

function hashStr(s) {
    let h = 0;
    for (let i = 0; i < s.length; i++) {
        h = (Math.imul(31, h) + s.charCodeAt(i)) | 0;
    }
    return h >>> 0;
}

function randNormal(rng) {
    // Box-Muller; one draw per call (the second u2 sample is wasted).
    const u1 = Math.max(rng(), 1e-10);
    const u2 = rng();
    return Math.sqrt(-2 * Math.log(u1)) * Math.cos(2 * Math.PI * u2);
}

// ─── Single season simulation ──────────────────────────────────────────────
/**
 * Run a single LHSP breeding-season simulation.
 *
 * @param {Object} params — { minThresh_F, maxThresh_F, minThresh_M, maxThresh_M,
 *                            foragingMean, foragingSD, eggTolerance }
 * @param {Function|number|string} [rngOrSeed] — RNG fn, numeric/string seed,
 *                                               or undefined (uses Math.random)
 * @returns {Object} season result; see fields at the bottom.
 */
export function runSeason(params, rngOrSeed) {
    const C = Constants;
    const rng = typeof rngOrSeed === 'function' ? rngOrSeed : makeRng(rngOrSeed);
    const eggTolerance = params.eggTolerance ?? C.DEFAULT_NEGLECT_MAX;

    // Egg state (mutable struct, not exposed externally)
    const egg = {
        alive: true,
        hatched: false,
        currDays: 0,
        hatchDays: C.START_HATCH_DAYS,
        currNeg: 0,
        totNeg: 0,
        maxNeg: 0,
        neglectMax: eggTolerance,
    };

    function eggDay(incubated) {
        egg.currDays++;
        if (incubated) {
            egg.currNeg = 0;
        } else {
            egg.currNeg++;
            egg.totNeg++;
            if (egg.currNeg > egg.maxNeg) egg.maxNeg = egg.currNeg;
            if (egg.maxNeg > egg.neglectMax) egg.alive = false;
            egg.hatchDays += C.NEGLECT_PENALTY;
        }
        if (egg.alive && egg.currDays >= egg.hatchDays) egg.hatched = true;
    }

    // Each parent is a small mutable struct
    function makeParent(sex) {
        const minKey = sex === 'female' ? 'minThresh_F' : 'minThresh_M';
        const maxKey = sex === 'female' ? 'maxThresh_F' : 'maxThresh_M';
        return {
            sex,
            state: sex === 'female' ? 'incubating' : 'foraging',
            previousDayState: sex === 'female' ? 'incubating' : 'foraging',
            energy: C.BASE_ENERGY,
            minThresh: params[minKey] ?? C.FORAGING_METABOLISM,
            maxThresh: params[maxKey] ?? C.BASE_ENERGY,
            foragingMean: params.foragingMean ?? C.FORAGING_MEAN,
            foragingSD: params.foragingSD ?? C.FORAGING_SD,
            foragingDays: 0,
            energyRecord: [],
        };
    }

    function parentDay(p) {
        if (p.state !== 'dead') p.energyRecord.push(p.energy);
        if (p.energy <= 0) p.state = 'dead';
        if (p.state === 'dead') {
            p.previousDayState = 'dead';
            return;
        }
        p.previousDayState = p.state;
        if (p.state === 'incubating') {
            p.energy -= C.INCUBATING_METABOLISM;
            if (p.energy <= p.minThresh) {
                p.state = 'foraging';
                p.foragingDays = 0;
            }
        } else {
            p.foragingDays++;
            p.energy -= C.FORAGING_METABOLISM;
            let intake = p.foragingMean + p.foragingSD * randNormal(rng);
            if (intake < 0) intake = 0;
            p.energy += intake;
            if (p.energy >= p.maxThresh && p.foragingDays > 1) {
                p.state = 'incubating';
            }
        }
    }

    const pf = makeParent('female');
    const pm = makeParent('male');
    pf.energy -= C.EGG_COST;       // female pays for the egg up front

    const history = [];            // chars: F / M / N
    const frames = [];             // per-day full snapshot for animation

    while (egg.alive && !egg.hatched && egg.currDays <= C.HATCH_DAYS_MAX) {
        const incubated = pf.state === 'incubating' || pm.state === 'incubating';
        eggDay(incubated);
        parentDay(pf);
        parentDay(pm);

        if (pf.state === 'dead' || pm.state === 'dead') {
            // record one final frame so the animation can show the end-state
            frames.push(snapshot(egg, pf, pm));
            break;
        }

        // Resolve return-overlap: whoever was foraging yesterday just returned;
        // the other parent is freed to leave.
        if (pf.state === 'incubating' && pm.state === 'incubating') {
            const fJustReturned = pf.previousDayState === 'foraging';
            const mJustReturned = pm.previousDayState === 'foraging';
            if (mJustReturned && !fJustReturned) {
                pf.state = 'foraging';
                pf.foragingDays = 0;
            } else if (fJustReturned && !mJustReturned) {
                pm.state = 'foraging';
                pm.foragingDays = 0;
            } else {
                if (rng() < 0.5) {
                    pf.state = 'foraging';
                    pf.foragingDays = 0;
                } else {
                    pm.state = 'foraging';
                    pm.foragingDays = 0;
                }
            }
        }

        history.push(
            pf.state === 'incubating' ? 'F'
            : pm.state === 'incubating' ? 'M'
            : 'N'
        );
        frames.push(snapshot(egg, pf, pm));
    }

    return {
        outcome: classifyOutcome(egg, pf, pm),
        hatched: egg.hatched,
        eggAlive: egg.alive,
        incubationDays: egg.currDays,
        totalNeglect: egg.totNeg,
        maxNeglect: egg.maxNeg,
        history: history.join(''),
        historyArray: history,
        frames,
        femaleAlive: pf.state !== 'dead',
        maleAlive: pm.state !== 'dead',
        femaleEnergy: pf.energyRecord,
        maleEnergy: pm.energyRecord,
        femaleEnergyEnd: pf.energyRecord.at(-1) ?? 0,
        maleEnergyEnd: pm.energyRecord.at(-1) ?? 0,
        femaleEnergyMean: meanOf(pf.energyRecord),
        maleEnergyMean: meanOf(pm.energyRecord),
    };
}

function snapshot(egg, pf, pm) {
    return {
        day: egg.currDays,
        eggAlive: egg.alive,
        eggHatched: egg.hatched,
        eggHatchDays: egg.hatchDays,
        eggCurrNeg: egg.currNeg,
        eggMaxNeg: egg.maxNeg,
        femaleState: pf.state,
        femaleEnergy: pf.energy,
        maleState: pm.state,
        maleEnergy: pm.energy,
    };
}

function classifyOutcome(egg, pf, pm) {
    const fDead = pf.state === 'dead';
    const mDead = pm.state === 'dead';
    if (fDead && mDead) return OUTCOMES.BOTH_DIED;
    if (fDead) return OUTCOMES.FEMALE_DIED;
    if (mDead) return OUTCOMES.MALE_DIED;
    if (!egg.alive) return OUTCOMES.EGG_DIED;
    if (egg.hatched) return OUTCOMES.HATCHED;
    return OUTCOMES.TIMEOUT;
}

function meanOf(arr) {
    if (!arr.length) return 0;
    let s = 0;
    for (const v of arr) s += v;
    return s / arr.length;
}

// ─── Replicate sweep helpers ───────────────────────────────────────────────
/**
 * Run `n` replicates of one parameter combo and return aggregate stats.
 * Uses successive seeds derived from `seed0` so reps are reproducible.
 */
export function runReplicates(params, n, seed0 = 0) {
    let hatched = 0, eggDied = 0, fDied = 0, mDied = 0, bothDied = 0, timeout = 0;
    let totHatchDays = 0, totMaxNeg = 0;
    const seasons = [];
    for (let i = 0; i < n; i++) {
        const r = runSeason(params, makeRng(seed0 + i));
        seasons.push(r);
        switch (r.outcome) {
            case OUTCOMES.HATCHED:     hatched++;  break;
            case OUTCOMES.EGG_DIED:    eggDied++;  break;
            case OUTCOMES.FEMALE_DIED: fDied++;    break;
            case OUTCOMES.MALE_DIED:   mDied++;    break;
            case OUTCOMES.BOTH_DIED:   bothDied++; break;
            case OUTCOMES.TIMEOUT:     timeout++;  break;
        }
        totHatchDays += r.incubationDays;
        totMaxNeg += r.maxNeglect;
    }
    return {
        n,
        seasons,
        hatchRate: hatched / n,
        eggDiedRate: eggDied / n,
        femaleDiedRate: fDied / n,
        maleDiedRate: mDied / n,
        bothDiedRate: bothDied / n,
        timeoutRate: timeout / n,
        parentSurvivalRate: (n - fDied - mDied - bothDied) / n,
        meanHatchDays: totHatchDays / n,
        meanMaxNeglect: totMaxNeg / n,
    };
}
