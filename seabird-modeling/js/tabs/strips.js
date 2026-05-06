// tabs/strips.js — Tab 3: 100 seasons stacked vertically as F/M/N stripes.
// Live-updates as sliders move.

import { runSeason, OUTCOME_COLOURS, OUTCOMES } from '../model.js';
import { chunked, makeLiveRunner } from '../sim.js';
import { bindRangeOutput } from '../app.js';

let lastResults = null;
let refresh = null;

const COLOURS = { F: '#f59e0b', M: '#0ea5e9', N: '#444' };

const OUTCOME_PRIORITY = {
    [OUTCOMES.HATCHED]: 0, [OUTCOMES.TIMEOUT]: 1, [OUTCOMES.EGG_DIED]: 2,
    [OUTCOMES.MALE_DIED]: 3, [OUTCOMES.FEMALE_DIED]: 4, [OUTCOMES.BOTH_DIED]: 5,
};

const SLIDER_IDS = [
    'strips-minF','strips-maxF','strips-minM','strips-maxM',
    'strips-fmean','strips-fsd','strips-egg','strips-reps',
];

export function init() {
    [
        ['strips-minF','strips-out-minF'], ['strips-maxF','strips-out-maxF'],
        ['strips-minM','strips-out-minM'], ['strips-maxM','strips-out-maxM'],
        ['strips-fmean','strips-out-fmean'], ['strips-fsd','strips-out-fsd'],
        ['strips-egg','strips-out-egg'], ['strips-reps','strips-out-reps'],
    ].forEach(([rid, oid]) => bindRangeOutput(byId(rid), byId(oid)));

    refresh = makeLiveRunner(runStrips, 220);
    SLIDER_IDS.forEach(id => byId(id).addEventListener('input', () => refresh()));
    byId('strips-sort').addEventListener('change', () => {
        if (lastResults) drawStrips(lastResults);
    });

    document.addEventListener('lhsp:loadParams', (ev) => {
        if (ev.detail.tab !== 'strips') return;
        const p = ev.detail.params;
        const set = (id, v) => {
            byId(id).value = v;
            byId(id.replace('strips-', 'strips-out-')).textContent = v;
        };
        set('strips-minF', p.minThresh_F);
        set('strips-maxF', p.maxThresh_F);
        set('strips-minM', p.minThresh_M);
        set('strips-maxM', p.maxThresh_M);
        set('strips-fmean', p.foragingMean);
        set('strips-fsd', p.foragingSD);
        set('strips-egg', p.eggTolerance);
        refresh(true);
    });

    refresh(true);
}

async function runStrips(signal) {
    const params = readParams();
    const reps = +byId('strips-reps').value;

    setStatus(`Running ${reps} seasons…`);

    const results = new Array(reps);
    const t0 = performance.now();
    const out = await chunked(reps, (i) => {
        results[i] = runSeason(params, 4242 + i);
    }, null, { signal });
    if (out.aborted) { setStatus('cancelled'); return; }

    setStatus(`${reps} seasons in ${((performance.now()-t0)/1000).toFixed(2)}s · ${summariseOutcomes(results)}`);
    lastResults = results;
    drawStrips(results);
}

function summariseOutcomes(results) {
    const counts = {};
    for (const r of results) counts[r.outcome] = (counts[r.outcome] ?? 0) + 1;
    return Object.entries(counts).sort()
        .map(([k, v]) => `${k}: ${v}`).join(' · ');
}

function drawStrips(results) {
    const canvas = byId('strips-canvas');
    const ctx = canvas.getContext('2d');
    const W = canvas.width;

    const sort = byId('strips-sort').value;
    const sorted = [...results.entries()];
    if (sort === 'outcome') {
        sorted.sort((a, b) => {
            const da = OUTCOME_PRIORITY[a[1].outcome] ?? 99;
            const db = OUTCOME_PRIORITY[b[1].outcome] ?? 99;
            if (da !== db) return da - db;
            return a[1].incubationDays - b[1].incubationDays;
        });
    } else if (sort === 'hatchDays') {
        sorted.sort((a, b) => a[1].incubationDays - b[1].incubationDays);
    } else if (sort === 'totalNeglect') {
        sorted.sort((a, b) => a[1].totalNeglect - b[1].totalNeglect);
    }

    const N = sorted.length;
    const rowH = Math.max(3, Math.floor(620 / N));
    const H = rowH * N + 12;
    canvas.height = H;
    ctx.clearRect(0, 0, W, H);

    const labelW = 140;
    const days = 60;
    const cellW = (W - labelW - 10) / days;

    for (let row = 0; row < N; row++) {
        const [, r] = sorted[row];
        const y = row * rowH + 4;

        ctx.fillStyle = OUTCOME_COLOURS[r.outcome] ?? '#888';
        ctx.fillRect(0, y, 6, rowH - 1);

        for (let d = 0; d < r.historyArray.length; d++) {
            ctx.fillStyle = COLOURS[r.historyArray[d]];
            ctx.fillRect(10 + d * cellW, y, cellW + 0.5, rowH - 1);
        }

        if (rowH >= 12 || row % Math.max(1, Math.ceil(N / 30)) === 0) {
            ctx.fillStyle = '#9aa6b2';
            ctx.font = '10px -apple-system, sans-serif';
            ctx.textAlign = 'left';
            ctx.fillText(
                `${r.outcome} · ${r.incubationDays}d · neg ${r.totalNeglect}`,
                12 + days * cellW + 4, y + rowH - 2,
            );
        }
    }

    ctx.fillStyle = '#9aa6b2';
    ctx.font = '10px -apple-system, sans-serif';
    ctx.textAlign = 'center';
    for (let d = 0; d <= days; d += 10) {
        const x = 10 + d * cellW;
        ctx.fillText(`${d}d`, x, H - 1);
    }
}

function readParams() {
    return {
        minThresh_F: +byId('strips-minF').value,
        maxThresh_F: +byId('strips-maxF').value,
        minThresh_M: +byId('strips-minM').value,
        maxThresh_M: +byId('strips-maxM').value,
        foragingMean: +byId('strips-fmean').value,
        foragingSD:   +byId('strips-fsd').value,
        eggTolerance: +byId('strips-egg').value,
    };
}

function setStatus(msg) { byId('strips-status').textContent = msg; }
function byId(id) { return document.getElementById(id); }
