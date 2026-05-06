// tabs/phase.js — Tab 4: phase portrait of (femaleEnergy, maleEnergy)
// trajectories. Each season is one polyline coloured by outcome.
// Live-updates as sliders move.

import { runSeason, OUTCOME_COLOURS } from '../model.js';
import { chunked, makeLiveRunner } from '../sim.js';
import { bindRangeOutput } from '../app.js';

const SLIDER_IDS = [
    'phase-minF','phase-maxF','phase-minM','phase-maxM',
    'phase-fmean','phase-fsd','phase-egg','phase-reps',
];

let refresh = null;

export function init() {
    [
        ['phase-minF','phase-out-minF'], ['phase-maxF','phase-out-maxF'],
        ['phase-minM','phase-out-minM'], ['phase-maxM','phase-out-maxM'],
        ['phase-fmean','phase-out-fmean'], ['phase-fsd','phase-out-fsd'],
        ['phase-egg','phase-out-egg'], ['phase-reps','phase-out-reps'],
    ].forEach(([rid, oid]) => bindRangeOutput(byId(rid), byId(oid)));

    refresh = makeLiveRunner(runPhase, 220);
    SLIDER_IDS.forEach(id => byId(id).addEventListener('input', () => refresh()));
    refresh(true);
}

async function runPhase(signal) {
    const params = readParams();
    const reps = +byId('phase-reps').value;

    setStatus(`Running ${reps} seasons…`);
    const results = new Array(reps);
    const t0 = performance.now();
    const out = await chunked(reps, (i) => {
        results[i] = runSeason(params, 7777 + i);
    }, null, { signal });
    if (out.aborted) { setStatus('cancelled'); return; }
    setStatus(`${reps} seasons in ${((performance.now()-t0)/1000).toFixed(2)}s`);

    renderPhase(results, params);
}

function renderPhase(results, params) {
    const traces = {};
    for (const r of results) {
        if (!traces[r.outcome]) {
            traces[r.outcome] = {
                x: [], y: [],
                mode: 'lines',
                type: 'scatter',
                name: r.outcome,
                line: { color: OUTCOME_COLOURS[r.outcome], width: 1 },
                opacity: 0.55,
                hoverinfo: 'skip',
                showlegend: true,
                legendgroup: r.outcome,
            };
        }
        const tr = traces[r.outcome];
        if (tr.x.length > 0) { tr.x.push(null); tr.y.push(null); }
        const fE = r.femaleEnergy, mE = r.maleEnergy;
        const len = Math.min(fE.length, mE.length);
        for (let k = 0; k < len; k++) { tr.x.push(fE[k]); tr.y.push(mE[k]); }
    }

    const shapes = [
        { type: 'line', x0: params.minThresh_F, x1: params.minThresh_F, y0: 0, y1: 1300,
          line: { color: 'rgba(229,72,72,0.4)', dash: 'dash', width: 1 } },
        { type: 'line', x0: params.maxThresh_F, x1: params.maxThresh_F, y0: 0, y1: 1300,
          line: { color: 'rgba(46,204,113,0.4)', dash: 'dash', width: 1 } },
        { type: 'line', x0: 0, x1: 1300, y0: params.minThresh_M, y1: params.minThresh_M,
          line: { color: 'rgba(229,72,72,0.4)', dash: 'dash', width: 1 } },
        { type: 'line', x0: 0, x1: 1300, y0: params.maxThresh_M, y1: params.maxThresh_M,
          line: { color: 'rgba(46,204,113,0.4)', dash: 'dash', width: 1 } },
    ];

    const layout = {
        paper_bgcolor: '#1f2630',
        plot_bgcolor:  '#1f2630',
        font: { color: '#e6edf3', family: '-apple-system, sans-serif' },
        title: 'Energy phase portrait — each line is one season',
        xaxis: { title: 'Female energy (kJ)', range: [0, 1300], gridcolor: '#2a313c', zerolinecolor: '#2a313c' },
        yaxis: { title: 'Male energy (kJ)',   range: [0, 1300], gridcolor: '#2a313c', zerolinecolor: '#2a313c' },
        shapes,
        annotations: [
            { x: params.minThresh_F, y: 1280, text: 'F hunger', showarrow: false,
              font: { color: '#e84a4a', size: 10 } },
            { x: params.maxThresh_F, y: 1280, text: 'F satiation', showarrow: false,
              font: { color: '#2ecc71', size: 10 } },
            { x: 1280, y: params.minThresh_M, text: 'M hunger', showarrow: false,
              font: { color: '#e84a4a', size: 10 }, xanchor: 'right' },
            { x: 1280, y: params.maxThresh_M, text: 'M satiation', showarrow: false,
              font: { color: '#2ecc71', size: 10 }, xanchor: 'right' },
        ],
        margin: { t: 60, r: 40, b: 60, l: 70 },
        legend: { font: { color: '#e6edf3' }, bgcolor: 'rgba(0,0,0,0)' },
    };

    Plotly.react(byId('phase-plot'), Object.values(traces), layout,
                 { responsive: true, displaylogo: false });
}

function readParams() {
    return {
        minThresh_F: +byId('phase-minF').value,
        maxThresh_F: +byId('phase-maxF').value,
        minThresh_M: +byId('phase-minM').value,
        maxThresh_M: +byId('phase-maxM').value,
        foragingMean: +byId('phase-fmean').value,
        foragingSD:   +byId('phase-fsd').value,
        eggTolerance: +byId('phase-egg').value,
    };
}

function setStatus(msg) { byId('phase-status').textContent = msg; }
function byId(id) { return document.getElementById(id); }
