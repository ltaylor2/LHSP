// tabs/tornado.js — Tab 5: one-at-a-time sensitivity analysis. Live-updates.

import { runReplicates, DEFAULT_PARAMS } from '../model.js';
import { chunked, makeLiveRunner } from '../sim.js';
import { bindRangeOutput } from '../app.js';

const PARAMS = [
    { key: 'minThresh_F',  label: 'F hunger'    },
    { key: 'maxThresh_F',  label: 'F satiation' },
    { key: 'minThresh_M',  label: 'M hunger'    },
    { key: 'maxThresh_M',  label: 'M satiation' },
    { key: 'foragingMean', label: 'Foraging mean' },
    { key: 'foragingSD',   label: 'Foraging SD'   },
    { key: 'eggTolerance', label: 'Egg tolerance' },
];

let refresh = null;

export function init() {
    bindRangeOutput(byId('trn-pert'), byId('trn-out-pert'), v => `±${v}%`);
    bindRangeOutput(byId('trn-reps'), byId('trn-out-reps'));

    refresh = makeLiveRunner(runTornado, 250);
    ['trn-pert','trn-reps'].forEach(id =>
        byId(id).addEventListener('input', () => refresh()));
    refresh(true);
}

async function runTornado(signal) {
    const pertPct = +byId('trn-pert').value / 100;
    const reps = +byId('trn-reps').value;
    const base = { ...DEFAULT_PARAMS };

    setStatus('Running…');

    const baseline = runReplicates(base, reps, 9000);

    const work = PARAMS.length * 2;
    const out = [];
    let i = 0;
    const t0 = performance.now();
    const status = await chunked(work, () => {
        const pIdx = Math.floor(i / 2);
        const isHigh = i % 2 === 1;
        const param = PARAMS[pIdx];
        const factor = isHigh ? (1 + pertPct) : (1 - pertPct);
        const params = { ...base };
        params[param.key] = Math.max(1, Math.round(base[param.key] * factor));
        const r = runReplicates(params, reps, 9000 + (pIdx + 1) * 1000 + (isHigh ? 7 : 0));
        out.push({ param, isHigh, hatch: r.hatchRate, value: params[param.key] });
        i++;
    }, null, { signal });
    if (status.aborted) { setStatus('cancelled'); return; }

    const dt = ((performance.now() - t0) / 1000).toFixed(2);
    setStatus(`Done in ${dt}s. Baseline hatch = ${(baseline.hatchRate*100).toFixed(1)}%.`);
    renderTornado(baseline, out, pertPct);
}

function renderTornado(baseline, results, pertPct) {
    const rows = PARAMS.map(p => {
        const lo = results.find(r => r.param.key === p.key && !r.isHigh);
        const hi = results.find(r => r.param.key === p.key && r.isHigh);
        return {
            label: p.label,
            low:  lo ? lo.hatch : baseline.hatchRate,
            high: hi ? hi.hatch : baseline.hatchRate,
        };
    });
    rows.forEach(r => {
        r.swing = Math.abs(r.high - r.low);
        r.fromLow  = r.low  - baseline.hatchRate;
        r.fromHigh = r.high - baseline.hatchRate;
    });
    rows.sort((a, b) => b.swing - a.swing);

    const labels = rows.map(r => r.label);
    const data = [
        {
            x: rows.map(r => r.fromLow),
            y: labels,
            orientation: 'h',
            type: 'bar',
            name: `−${(pertPct*100).toFixed(0)}%`,
            marker: { color: '#e84a4a' },
            text: rows.map(r => `${(r.low*100).toFixed(0)}%`),
            textposition: 'outside',
            hovertemplate: '%{y}: %{x:+.2%} from baseline<extra></extra>',
        },
        {
            x: rows.map(r => r.fromHigh),
            y: labels,
            orientation: 'h',
            type: 'bar',
            name: `+${(pertPct*100).toFixed(0)}%`,
            marker: { color: '#2ecc71' },
            text: rows.map(r => `${(r.high*100).toFixed(0)}%`),
            textposition: 'outside',
            hovertemplate: '%{y}: %{x:+.2%} from baseline<extra></extra>',
        },
    ];

    const layout = {
        paper_bgcolor: '#1f2630',
        plot_bgcolor:  '#1f2630',
        font: { color: '#e6edf3', family: '-apple-system, sans-serif' },
        title: `Sensitivity tornado · baseline hatch rate = ${(baseline.hatchRate*100).toFixed(1)}%`,
        xaxis: {
            title: 'Δ hatch rate (proportion)',
            tickformat: '+.0%',
            zeroline: true, zerolinecolor: '#9aa6b2', gridcolor: '#2a313c',
        },
        yaxis: { autorange: 'reversed', gridcolor: '#2a313c' },
        barmode: 'overlay',
        margin: { t: 60, r: 80, b: 60, l: 130 },
        legend: { font: { color: '#e6edf3' } },
    };

    Plotly.react(byId('trn-plot'), data, layout, { responsive: true, displaylogo: false });
}

function setStatus(msg) { byId('trn-status').textContent = msg; }
function byId(id) { return document.getElementById(id); }
