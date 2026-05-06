// tabs/heatmap.js — Tab 2: live-updating hatch-rate (or other metric) over a
// (hunger × satiation) grid.
//
// Every slider / select binds to a debounced `makeLiveRunner` so the heatmap
// re-renders as the user drags. In-flight sweeps are cancelled when a new
// one starts.

import { gridSweep, linspace, makeLiveRunner } from '../sim.js';
import { bindRangeOutput } from '../app.js';

let lastSweep = null;

const X_MIN = 100, X_MAX = 1100;
const Y_MIN = 200, Y_MAX = 1200;

const METRIC_LABELS = {
    hatchRate:           { label: 'Hatch rate',       fmt: v => `${(v*100).toFixed(0)}%`, scale: 'Viridis', range: [0,1]  },
    parentSurvivalRate:  { label: 'Parent survival',  fmt: v => `${(v*100).toFixed(0)}%`, scale: 'Cividis', range: [0,1]  },
    meanHatchDays:       { label: 'Mean hatch days',  fmt: v => v.toFixed(1),             scale: 'YlGnBu',  range: null   },
    meanMaxNeglect:      { label: 'Mean max neglect', fmt: v => v.toFixed(1),             scale: 'Hot',     range: null   },
};

let refresh = null;

export function init() {
    bindRangeOutput(byId('hm-res'),  byId('hm-out-res'),  v => `${v} × ${v}`);
    bindRangeOutput(byId('hm-reps'), byId('hm-out-reps'));
    bindRangeOutput(byId('hm-fmean'),byId('hm-out-fmean'));
    bindRangeOutput(byId('hm-fsd'),  byId('hm-out-fsd'));
    bindRangeOutput(byId('hm-egg'),  byId('hm-out-egg'));

    refresh = makeLiveRunner(runSweep, 220);

    // Re-run on any slider change
    ['hm-res','hm-reps','hm-fmean','hm-fsd','hm-egg'].forEach(id =>
        byId(id).addEventListener('input', () => refresh()));
    // Metric change just re-renders existing data (no recomputation)
    byId('hm-metric').addEventListener('change', () => {
        if (lastSweep) renderHeatmap(lastSweep);
    });

    // Initial run
    refresh(true);
}

async function runSweep(signal) {
    const res = +byId('hm-res').value;
    const reps = +byId('hm-reps').value;
    const xs = linspace(X_MIN, X_MAX, res);
    const ys = linspace(Y_MIN, Y_MAX, res);

    const grid = {};
    for (const k of Object.keys(METRIC_LABELS)) {
        grid[k] = Array.from({length: res}, () => Array(res).fill(NaN));
    }
    const paramsGrid = Array.from({length: res}, () => Array(res).fill(null));

    const baseParams = {
        foragingMean: +byId('hm-fmean').value,
        foragingSD:   +byId('hm-fsd').value,
        eggTolerance: +byId('hm-egg').value,
    };

    setStatus(`Sweeping ${res*res} cells × ${reps} reps…`);
    const t0 = performance.now();
    const result = await gridSweep({
        xs, ys, reps,
        paramAt: (x, y) => ({
            ...baseParams,
            minThresh_F: x, minThresh_M: x,
            maxThresh_F: y, maxThresh_M: y,
        }),
        seed0: 1234,
        onCell: (i, j, r, params) => {
            for (const k of Object.keys(METRIC_LABELS)) grid[k][j][i] = r[k];
            paramsGrid[j][i] = params;
        },
        signal,
    });
    if (result.aborted) { setStatus('cancelled (newer slider value)'); return; }

    const dt = ((performance.now() - t0) / 1000).toFixed(2);
    setStatus(`${res*res*reps} seasons in ${dt}s`);

    lastSweep = { xs, ys, grid, paramsGrid };
    renderHeatmap(lastSweep);
}

function renderHeatmap({ xs, ys, grid, paramsGrid }) {
    const metric = byId('hm-metric').value;
    const meta = METRIC_LABELS[metric];
    const z = grid[metric];

    const data = [{
        z, x: xs, y: ys,
        type: 'heatmap',
        colorscale: meta.scale,
        zmin: meta.range ? meta.range[0] : undefined,
        zmax: meta.range ? meta.range[1] : undefined,
        hovertemplate: 'hunger: %{x}<br>satiation: %{y}<br>' + meta.label + ': %{z:.3f}<extra></extra>',
        colorbar: { title: meta.label, tickfont: { color: '#e6edf3' } },
    }];

    const layout = {
        paper_bgcolor: '#1f2630',
        plot_bgcolor:  '#1f2630',
        font: { color: '#e6edf3', family: '-apple-system, sans-serif' },
        title: meta.label + ' across hunger × satiation thresholds',
        xaxis: { title: 'Hunger threshold (kJ)',     gridcolor: '#2a313c' },
        yaxis: { title: 'Satiation threshold (kJ)',  gridcolor: '#2a313c' },
        margin: { t: 60, r: 40, b: 60, l: 70 },
    };

    const plot = byId('hm-plot');
    Plotly.react(plot, data, layout, { responsive: true, displaylogo: false });

    // Click handoff to strips tab
    plot.on('plotly_click', (ev) => {
        if (!ev.points || !ev.points.length) return;
        const p = ev.points[0];
        const i = p.pointNumber[1], j = p.pointNumber[0];
        const params = paramsGrid[j][i];
        if (!params) return;
        document.dispatchEvent(new CustomEvent('lhsp:loadParams', {
            detail: { tab: 'strips', params },
        }));
        document.querySelector('.tab[data-tab="strips"]').click();
    });
}

function setStatus(msg) { byId('hm-status').textContent = msg; }
function byId(id) { return document.getElementById(id); }
