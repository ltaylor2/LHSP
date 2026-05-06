// sim.js — shared helpers for running parameter sweeps without freezing the UI.
//
// We don't use Web Workers (yet) because the simulation is small enough that
// chunking on the main thread keeps everything below ~1 second and the UX
// is plenty responsive. If future workloads grow, swap chunked() for a
// worker-pool here without touching tab modules.

import { runSeason, runReplicates, OUTCOMES } from './model.js';

/**
 * Run an async iteration that yields back to the event loop every `chunkMs`.
 * Calls `onProgress(done, total)` periodically.
 *
 * If `signal` is given (an AbortSignal), the loop checks between chunks and
 * resolves early with `{aborted: true, completed: i}`.
 */
export function chunked(total, body, onProgress, opts = {}) {
    const { chunkMs = 40, signal = null } = opts;
    return new Promise((resolve) => {
        let i = 0;
        function step() {
            if (signal && signal.aborted) {
                resolve({ aborted: true, completed: i });
                return;
            }
            const start = performance.now();
            while (i < total && performance.now() - start < chunkMs) {
                body(i);
                i++;
            }
            if (onProgress) onProgress(i, total);
            if (i < total) setTimeout(step, 0);
            else resolve({ aborted: false, completed: i });
        }
        step();
    });
}

/**
 * Sweep a 2-D grid of (xs × ys), running `reps` replicates per cell.
 */
export async function gridSweep({xs, ys, reps, paramAt, seed0 = 0, onCell, onProgress, signal}) {
    const cells = xs.length * ys.length;
    return await chunked(cells, (k) => {
        const j = Math.floor(k / xs.length);
        const i = k % xs.length;
        const params = paramAt(xs[i], ys[j]);
        const r = runReplicates(params, reps, seed0 + k * reps);
        if (onCell) onCell(i, j, r, params);
    }, onProgress ? (d, t) => onProgress(d, t) : null, { signal });
}

export function linspace(min, max, n) {
    if (n <= 1) return [min];
    const step = (max - min) / (n - 1);
    return Array.from({length: n}, (_, i) => +(min + i * step).toFixed(4));
}

/**
 * Make a debounced "live runner" for slider-driven sweeps.
 *
 *   const refresh = makeLiveRunner(async (signal) => { ...do work... }, 220);
 *   slider.addEventListener('input', refresh);
 *
 * Each call cancels any in-flight job, waits `debounceMs`, then runs the
 * work function with a fresh AbortSignal. If a new call comes in mid-flight,
 * the running job sees `signal.aborted = true` and exits early.
 */
export function makeLiveRunner(workFn, debounceMs = 220) {
    let timer = null;
    let abort = null;
    function trigger(immediate = false) {
        clearTimeout(timer);
        const fire = async () => {
            if (abort) abort.abort();
            const ac = new AbortController();
            abort = ac;
            try { await workFn(ac.signal); }
            finally { if (abort === ac) abort = null; }
        };
        if (immediate) fire();
        else timer = setTimeout(fire, debounceMs);
    }
    return trigger;
}

export { runSeason, runReplicates, OUTCOMES };
