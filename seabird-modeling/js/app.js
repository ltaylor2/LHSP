// app.js — top-level wiring: tab navigation + lazy init of each tab module.
//
// Each tab is a self-contained ES module with an `init()` function that's
// called the first time the user opens that tab. This keeps the cost of
// loading the page low (only the replay tab does anything until you click).

import { init as initReplay  } from './tabs/replay.js';
import { init as initHeatmap } from './tabs/heatmap.js';
import { init as initStrips  } from './tabs/strips.js';
import { init as initPhase   } from './tabs/phase.js';
import { init as initTornado } from './tabs/tornado.js';
import { init as initPareto  } from './tabs/pareto.js';

const initFns = {
    replay:  initReplay,
    heatmap: initHeatmap,
    strips:  initStrips,
    phase:   initPhase,
    tornado: initTornado,
    pareto:  initPareto,
};

const initialised = new Set();

function activate(tabId) {
    document.querySelectorAll('.tab').forEach(btn => {
        btn.classList.toggle('is-active', btn.dataset.tab === tabId);
    });
    document.querySelectorAll('.tab-panel').forEach(panel => {
        panel.hidden = panel.id !== `tab-${tabId}`;
    });
    if (!initialised.has(tabId) && initFns[tabId]) {
        try {
            initFns[tabId]();
            initialised.add(tabId);
        } catch (e) {
            console.error(`Failed to init tab ${tabId}:`, e);
        }
    }
}

document.querySelectorAll('.tab').forEach(btn => {
    btn.addEventListener('click', () => activate(btn.dataset.tab));
});

// Tab driven by URL hash (so deep links + manual URL edits both work)
function activateFromHash() {
    const tab = window.location.hash.replace('#', '');
    activate(initFns[tab] ? tab : 'replay');
}
activateFromHash();
window.addEventListener('hashchange', activateFromHash);

// Update hash without reloading when tabs are clicked
document.querySelectorAll('.tab').forEach(btn => {
    btn.addEventListener('click', () => {
        history.replaceState(null, '', `#${btn.dataset.tab}`);
    });
});

// Tiny shared helper so each tab module can wire `<input type="range">`
// → its `<output>` display in one line.
export function bindRangeOutput(rangeEl, outEl, formatter = v => v) {
    if (!rangeEl || !outEl) return;
    const sync = () => { outEl.textContent = formatter(rangeEl.value); };
    rangeEl.addEventListener('input', sync);
    sync();
}
