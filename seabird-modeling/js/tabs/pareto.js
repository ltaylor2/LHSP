// tabs/pareto.js — Tab 6: Pareto front of (hatch rate, parent survival rate).
// Live-updates as sliders move.

import { gridSweep, linspace, makeLiveRunner } from '../sim.js';
import { bindRangeOutput } from '../app.js';

const X_MIN = 100, X_MAX = 1100;
const Y_MIN = 200, Y_MAX = 1200;

let refresh = null;

export function init() {
    bindRangeOutput(byId('pf-res'),  byId('pf-out-res'),  v => `${v} × ${v}`);
    bindRangeOutput(byId('pf-reps'), byId('pf-out-reps'));
    bindRangeOutput(byId('pf-fmean'),byId('pf-out-fmean'));
    bindRangeOutput(byId('pf-fsd'),  byId('pf-out-fsd'));
    bindRangeOutput(byId('pf-egg'),  byId('pf-out-egg'));

    refresh = makeLiveRunner(runGrid, 240);
    ['pf-res','pf-reps','pf-fmean','pf-fsd','pf-egg'].forEach(id =>
        byId(id).addEventListener('input', () => refresh()));
    refresh(true);
}

async function runGrid(signal) {
    const res = +byId('pf-res').value;
    const reps = +byId('pf-reps').value;
    const xs = linspace(X_MIN, X_MAX, res);
    const ys = linspace(Y_MIN, Y_MAX, res);

    const baseParams = {
        foragingMean: +byId('pf-fmean').value,
        foragingSD:   +byId('pf-fsd').value,
        eggTolerance: +byId('pf-egg').value,
    };

    setStatus(`Sweeping ${res*res} cells × ${reps} reps…`);

    const points = [];
    const t0 = performance.now();
    const out = await gridSweep({
        xs, ys, reps,
        paramAt: (x, y) => ({
            ...baseParams,
            minThresh_F: x, minThresh_M: x,
            maxThresh_F: y, maxThresh_M: y,
        }),
        seed0: 5555,
        onCell: (i, j, r, params) => {
            points.push({
                hunger: xs[i], satiation: ys[j],
                hatch: r.hatchRate,
                survival: r.parentSurvivalRate,
                params,
            });
        },
        signal,
    });
    if (out.aborted) { setStatus('cancelled'); return; }

    const dt = ((performance.now() - t0) / 1000).toFixed(2);
    setStatus(`${res*res*reps} seasons in ${dt}s`);
    renderPareto(points);
}

function paretoFrontIndices(points) {
    const front = [];
    for (let i = 0; i < points.length; i++) {
        const a = points[i];
        let dominated = false;
        for (let j = 0; j < points.length; j++) {
            if (i === j) continue;
            const b = points[j];
            if (b.hatch >= a.hatch && b.survival >= a.survival &&
                (b.hatch > a.hatch || b.survival > a.survival)) {
                dominated = true; break;
            }
        }
        if (!dominated) front.push(i);
    }
    return new Set(front);
}

function renderPareto(points) {
    const front = paretoFrontIndices(points);
    const dominated = points.map((_, i) => i).filter(i => !front.has(i));
    const frontIdx = [...front];
    frontIdx.sort((a, b) => points[a].hatch - points[b].hatch);

    const trace1 = {
        x: dominated.map(i => points[i].hatch),
        y: dominated.map(i => points[i].survival),
        mode: 'markers',
        type: 'scatter',
        name: 'dominated',
        marker: { color: '#9aa6b2', size: 9, opacity: 0.65 },
        text: dominated.map(i => `hunger ${points[i].hunger}\nsatiation ${points[i].satiation}`),
        hovertemplate: 'hatch %{x:.2f}<br>survival %{y:.2f}<br>%{text}<extra></extra>',
    };
    const trace2 = {
        x: frontIdx.map(i => points[i].hatch),
        y: frontIdx.map(i => points[i].survival),
        mode: 'markers+lines',
        type: 'scatter',
        name: 'Pareto front',
        marker: { color: '#2ecc71', size: 13, line: { color: '#fff', width: 1 } },
        line: { color: '#2ecc71', width: 2 },
        text: frontIdx.map(i => `hunger ${points[i].hunger}\nsatiation ${points[i].satiation}`),
        hovertemplate: 'hatch %{x:.2f}<br>survival %{y:.2f}<br>%{text}<extra></extra>',
    };

    const layout = {
        paper_bgcolor: '#1f2630',
        plot_bgcolor:  '#1f2630',
        font: { color: '#e6edf3', family: '-apple-system, sans-serif' },
        title: 'Hatch success vs parent survival across (hunger × satiation) combos',
        xaxis: { title: 'Hatch rate', range: [-0.02, 1.02], tickformat: '.0%', gridcolor: '#2a313c' },
        yaxis: { title: 'Parent survival rate', range: [-0.02, 1.02], tickformat: '.0%', gridcolor: '#2a313c' },
        margin: { t: 60, r: 40, b: 60, l: 70 },
        legend: { font: { color: '#e6edf3' } },
    };

    Plotly.react(byId('pf-plot'), [trace1, trace2], layout,
                 { responsive: true, displaylogo: false });
}

function setStatus(msg) { byId('pf-status').textContent = msg; }
function byId(id) { return document.getElementById(id); }
