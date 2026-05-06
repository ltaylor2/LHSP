// tabs/replay.js — Tab 1: top-down Kent-Island colony replay (smooth vector style).
//
// Rendering is done with regular Canvas2D paths/fills/strokes (no pixel-art
// upscaling), giving a soft cartoonish look. The simulation logic is the
// same C++-port `runSeason` from model.js; this file just visualises it.
//
// Key behaviours:
//   • One long, narrow Kent-Island shape (no satellite islands, no labels).
//   • Each pair gets a burrow rejection-sampled in the island interior.
//   • Birds are drawn next to the burrow so the egg stays visible.
//   • Egg colour gradients from cream → green when on track to hatch, and
//     cream → orange → red as neglect grows; bright green when hatched, dark
//     red when dead.
//   • When the season ends, surviving birds ease back to their home spot
//     and the rAF loop halts (CPU drops to zero).

import { runSeason, makeRng } from '../model.js';
import { bindRangeOutput } from '../app.js';

// ─── Canvas geometry ───────────────────────────────────────────────────────
const W = 1200, H = 700;
const KENT_CX = 600, KENT_CY = 350;
const KENT_RX = 110;     // half-width
const KENT_RY = 290;     // half-height (long N-S)

// ─── Colours ───────────────────────────────────────────────────────────────
const COL = {
    deepWater:   '#062542',
    midWater:    '#0f3a64',
    shallow:     '#2675a3',
    surf:        '#a8d5e8',
    beach:       '#cdaa72',
    grass:       '#5a8c44',
    grassDark:   '#446c33',
    forest:      '#2c5224',
    burrowDirt:  '#7a5a3a',
    burrowMouth: '#1a0f08',
    f:           '#d09455',
    fDark:       '#6b3d12',
    m:           '#6c83a4',
    mDark:       '#23304a',
    rump:        '#fdfbef',
    deadBird:    '#7c8290',
};

// ─── Animation state ───────────────────────────────────────────────────────
let pairs = [];
let dayT = 0;
let playing = true;
let mainCtx = null;
let baseMap = null;             // pre-rendered island layer
let kentPath = null;            // outline (used for burrow placement test)
let interiorPath = null;        // tighter interior (no burrows on coast)
let rafHandle = null;
let lastTickAt = 0;
let frozen = false;

export function init() {
    [
        ['replay-npairs','replay-out-npairs'],
        ['replay-minF','replay-out-minF'], ['replay-maxF','replay-out-maxF'],
        ['replay-minM','replay-out-minM'], ['replay-maxM','replay-out-maxM'],
        ['replay-fmean','replay-out-fmean'], ['replay-fsd','replay-out-fsd'],
        ['replay-egg','replay-out-egg'],
    ].forEach(([rid, oid]) => bindRangeOutput(byId(rid), byId(oid)));
    bindRangeOutput(byId('replay-speed'), byId('replay-out-speed'),
                    v => `${v} day${v === '1' ? '' : 's'}/sec`);

    setupSameForBoth();

    byId('replay-run').addEventListener('click', rebuildAndStart);
    byId('replay-reset').addEventListener('click', resetToFieldDefaults);
    byId('replay-play-toggle').addEventListener('click', togglePlay);
    byId('replay-step-back').addEventListener('click', () => stepTo(dayT - 1));
    byId('replay-step-fwd').addEventListener('click', () => stepTo(dayT + 1));

    let rebuildTimer = null;
    function scheduleRebuild() {
        clearTimeout(rebuildTimer);
        rebuildTimer = setTimeout(rebuildAndStart, 250);
    }
    [
        'replay-npairs',
        'replay-minF', 'replay-maxF', 'replay-minM', 'replay-maxM',
        'replay-fmean', 'replay-fsd', 'replay-egg', 'replay-seed',
    ].forEach(id => byId(id).addEventListener('input', scheduleRebuild));

    const main = byId('replay-canvas');
    mainCtx = main.getContext('2d');
    mainCtx.imageSmoothingEnabled = true;
    main.style.imageRendering = 'auto';

    rebuildBaseMap();
    rebuildAndStart();
}

// ─── "Same params for both sexes" toggle ──────────────────────────────────
function setupSameForBoth() {
    const sameBox = byId('replay-sameForBoth');
    const maleGroup = byId('replay-male-group');
    const minF = byId('replay-minF'), maxF = byId('replay-maxF');
    const minM = byId('replay-minM'), maxM = byId('replay-maxM');
    function syncMale() {
        if (sameBox.checked) {
            minM.value = minF.value; maxM.value = maxF.value;
            byId('replay-out-minM').textContent = minM.value;
            byId('replay-out-maxM').textContent = maxM.value;
        }
    }
    function applySame() {
        const same = sameBox.checked;
        maleGroup.style.opacity = same ? 0.5 : 1;
        [minM, maxM].forEach(el => el.disabled = same);
        if (same) syncMale();
    }
    sameBox.addEventListener('change', () => { applySame(); rebuildAndStart(); });
    minF.addEventListener('input', syncMale);
    maxF.addEventListener('input', syncMale);
    applySame();
}

// ─── Kent Island shape ─────────────────────────────────────────────────────
// Returns a multiplier on the base ellipse radius for angle θ.
// Asymmetric: relatively smooth on the east, with two western bays.
function islandRadius(theta) {
    let r = 1.0;
    // Gentle global wobble
    r += 0.045 * Math.sin(theta * 5)
       + 0.030 * Math.cos(theta * 8 + 1.0)
       + 0.018 * Math.sin(theta * 13 + 2.4);
    // West-side bays only (between θ = π/2 and θ = 3π/2, i.e. the western half)
    const cs = Math.cos(theta);          // +1 east, -1 west
    const westMask = (1 - cs) / 2;       // 0..1
    // Bay 1 — north-west
    r -= westMask * 0.16 * Math.exp(-Math.pow(theta - 1.18 * Math.PI, 2) / 0.05);
    // Bay 2 — south-west
    r -= westMask * 0.10 * Math.exp(-Math.pow(theta - 0.78 * Math.PI, 2) / 0.06);
    return r;
}

function buildIslandPath(rxScale = 1, ryScale = 1) {
    const path = new Path2D();
    const N = 240;
    for (let i = 0; i <= N; i++) {
        const t = (i / N) * Math.PI * 2;
        const r = islandRadius(t);
        const x = KENT_CX + Math.cos(t) * KENT_RX * rxScale * r;
        const y = KENT_CY + Math.sin(t) * KENT_RY * ryScale * r;
        if (i === 0) path.moveTo(x, y);
        else path.lineTo(x, y);
    }
    path.closePath();
    return path;
}

function rebuildBaseMap() {
    baseMap = document.createElement('canvas');
    baseMap.width = W; baseMap.height = H;
    const ctx = baseMap.getContext('2d');
    ctx.imageSmoothingEnabled = true;

    // Ocean gradient (subtle radial darkening from island to corners)
    const og = ctx.createRadialGradient(KENT_CX, KENT_CY, 60, KENT_CX, KENT_CY, 900);
    og.addColorStop(0, COL.midWater);
    og.addColorStop(1, COL.deepWater);
    ctx.fillStyle = og;
    ctx.fillRect(0, 0, W, H);

    kentPath     = buildIslandPath();
    interiorPath = buildIslandPath(0.78, 0.88);   // a bit smaller — burrow-safe zone

    // Concentric strokes around the coastline produce surf + beach rings
    ctx.lineJoin = 'round';
    ctx.lineCap  = 'round';

    ctx.lineWidth   = 36;
    ctx.strokeStyle = COL.shallow;
    ctx.stroke(kentPath);

    ctx.lineWidth   = 22;
    ctx.strokeStyle = COL.surf;
    ctx.stroke(kentPath);

    ctx.lineWidth   = 12;
    ctx.strokeStyle = COL.beach;
    ctx.stroke(kentPath);

    // Grass fill (covers the inside-half of the strokes above)
    const gg = ctx.createRadialGradient(KENT_CX, KENT_CY, 30, KENT_CX, KENT_CY, KENT_RY);
    gg.addColorStop(0, COL.grass);
    gg.addColorStop(1, COL.grassDark);
    ctx.fillStyle = gg;
    ctx.fill(kentPath);

    // Stylised forest patches inside (deterministic-pseudo placement)
    const seedRng = makeRng('forest-patches');
    ctx.fillStyle = COL.forest;
    for (let i = 0; i < 70; i++) {
        const t = seedRng() * Math.PI * 2;
        const rad = Math.sqrt(seedRng()) * 0.85;
        const x = KENT_CX + Math.cos(t) * KENT_RX * rad * islandRadius(t);
        const y = KENT_CY + Math.sin(t) * KENT_RY * rad * islandRadius(t);
        if (!ctx.isPointInPath(interiorPath, x, y)) continue;
        const rx = 6 + seedRng() * 8;
        const ry = rx * (0.7 + seedRng() * 0.4);
        ctx.globalAlpha = 0.55 + seedRng() * 0.25;
        ctx.beginPath();
        ctx.ellipse(x, y, rx, ry, seedRng() * Math.PI, 0, Math.PI * 2);
        ctx.fill();
    }
    ctx.globalAlpha = 1;

    // Compass rose (top-right) — small, no labels other than the N tick
    drawCompass(ctx);
}

function drawCompass(ctx) {
    const cx = W - 50, cy = 50;
    ctx.save();
    ctx.fillStyle = 'rgba(230,237,243,0.85)';
    ctx.strokeStyle = 'rgba(230,237,243,0.5)';
    ctx.lineWidth = 1;
    // Outer circle
    ctx.beginPath();
    ctx.arc(cx, cy, 16, 0, Math.PI * 2);
    ctx.stroke();
    // North arrow (filled triangle)
    ctx.beginPath();
    ctx.moveTo(cx, cy - 14);
    ctx.lineTo(cx - 4, cy);
    ctx.lineTo(cx + 4, cy);
    ctx.closePath();
    ctx.fill();
    // 'N' label
    ctx.font = 'bold 11px -apple-system, sans-serif';
    ctx.textAlign = 'center';
    ctx.textBaseline = 'top';
    ctx.fillText('N', cx, cy - 30);
    ctx.restore();
}

// ─── Pair generation ───────────────────────────────────────────────────────
function readParams() {
    const same = byId('replay-sameForBoth').checked;
    const minF = +byId('replay-minF').value, maxF = +byId('replay-maxF').value;
    return {
        minThresh_F: minF, maxThresh_F: maxF,
        minThresh_M: same ? minF : +byId('replay-minM').value,
        maxThresh_M: same ? maxF : +byId('replay-maxM').value,
        foragingMean: +byId('replay-fmean').value,
        foragingSD:   +byId('replay-fsd').value,
        eggTolerance: +byId('replay-egg').value,
    };
}

function rebuildAndStart() {
    const n = +byId('replay-npairs').value;
    const params = readParams();
    const seedStr = byId('replay-seed').value.trim() || 'kent';
    const colonyRng = makeRng(seedStr);

    const newPairs = [];
    const usedSpots = [];
    const MIN_SEP_SQ = 36 * 36;

    for (let i = 0; i < n; i++) {
        const burrow = sampleBurrow(colonyRng, usedSpots, MIN_SEP_SQ);
        usedSpots.push(burrow);

        const pairSeed = Math.floor(colonyRng() * 2 ** 31);
        const result = runSeason(params, pairSeed);

        const fHome = { x: burrow.x - 18, y: burrow.y - 4 };
        const mHome = { x: burrow.x + 18, y: burrow.y - 4 };
        const angleF = colonyRng() * Math.PI * 2;
        const angleM = (angleF + Math.PI + (colonyRng() - 0.5) * 1.0) % (Math.PI * 2);

        newPairs.push({
            result,
            burrow,
            seed: pairSeed,
            female: makeBird('female', fHome, angleF, colonyRng),
            male:   makeBird('male',   mHome, angleM, colonyRng),
        });
    }

    pairs = newPairs;
    dayT = 0;
    playing = true;
    frozen = false;
    byId('replay-play-toggle').textContent = 'Pause';
    if (rafHandle === null) {
        lastTickAt = performance.now();
        rafHandle = requestAnimationFrame(tick);
    }
}

function sampleBurrow(rng, usedSpots, minSepSq) {
    for (let attempt = 0; attempt < 600; attempt++) {
        const t = rng() * Math.PI * 2;
        const rad = Math.sqrt(rng()) * 0.85;
        const r = islandRadius(t);
        const x = KENT_CX + Math.cos(t) * KENT_RX * rad * r;
        const y = KENT_CY + Math.sin(t) * KENT_RY * rad * r;
        if (!mainCtx.isPointInPath(interiorPath, x, y)) continue;
        const tooClose = usedSpots.some(s =>
            (s.x - x) ** 2 + (s.y - y) ** 2 < minSepSq);
        if (!tooClose) return { x, y };
    }
    // Fallback — accept any point in the interior
    for (let attempt = 0; attempt < 200; attempt++) {
        const t = rng() * Math.PI * 2;
        const rad = Math.sqrt(rng()) * 0.85;
        const r = islandRadius(t);
        const x = KENT_CX + Math.cos(t) * KENT_RX * rad * r;
        const y = KENT_CY + Math.sin(t) * KENT_RY * rad * r;
        if (mainCtx.isPointInPath(interiorPath, x, y)) return { x, y };
    }
    return { x: KENT_CX, y: KENT_CY };
}

function makeBird(sex, home, angle, rng) {
    return {
        sex,
        home,
        pos:    { x: home.x, y: home.y },
        target: { x: home.x, y: home.y },
        wander: { x: home.x + Math.cos(angle) * 320, y: home.y + Math.sin(angle) * 200 },
        wanderVel: { x: 0, y: 0 },
        wanderJitter: 0.6 + rng() * 0.8,
        heading: angle,
    };
}

function resetToFieldDefaults() {
    byId('replay-minF').value  = 200;  byId('replay-maxF').value  = 900;
    byId('replay-minM').value  = 200;  byId('replay-maxM').value  = 900;
    byId('replay-fmean').value = 162;  byId('replay-fsd').value   = 47;
    byId('replay-egg').value   = 7;
    [
        ['replay-minF','replay-out-minF'], ['replay-maxF','replay-out-maxF'],
        ['replay-minM','replay-out-minM'], ['replay-maxM','replay-out-maxM'],
        ['replay-fmean','replay-out-fmean'], ['replay-fsd','replay-out-fsd'],
        ['replay-egg','replay-out-egg'],
    ].forEach(([rid, oid]) => byId(oid).textContent = byId(rid).value);
    rebuildAndStart();
}

function togglePlay() {
    playing = !playing;
    byId('replay-play-toggle').textContent = playing ? 'Pause' : 'Play';
    unfreeze();
}

function stepTo(t) {
    const max = maxSeasonLen();
    dayT = clamp(t, 0, Math.max(0, max - 1));
    playing = false;
    byId('replay-play-toggle').textContent = 'Play';
    unfreeze();
}

function unfreeze() {
    if (frozen) {
        frozen = false;
        if (rafHandle === null) {
            lastTickAt = performance.now();
            rafHandle = requestAnimationFrame(tick);
        }
    }
}

function maxSeasonLen() {
    let m = 1;
    for (const p of pairs) m = Math.max(m, p.result.frames.length);
    return m;
}

// ─── Animation tick ────────────────────────────────────────────────────────
function tick(now) {
    rafHandle = null;
    if (frozen) return;

    const dt = Math.min(0.1, (now - lastTickAt) / 1000);
    lastTickAt = now;

    if (playing && pairs.length > 0) {
        const speed = +byId('replay-speed').value;
        dayT += dt * speed;
        const maxLen = maxSeasonLen();
        if (dayT >= maxLen - 1) {
            dayT = Math.max(0, maxLen - 1);
            playing = false;
            byId('replay-play-toggle').textContent = 'Play';
        }
    }

    const seasonDone = !playing && dayT >= maxSeasonLen() - 1;

    let stillSettling = false;
    for (const p of pairs) {
        const f = currentFrame(p);
        if (!f) continue;
        const fState = effectiveState(f.femaleState, seasonDone);
        const mState = effectiveState(f.maleState,   seasonDone);
        const fStill = updateBird(p.female, fState, p.burrow, dt);
        const mStill = updateBird(p.male,   mState, p.burrow, dt);
        if (fStill || mStill) stillSettling = true;
    }

    drawAll();

    if (seasonDone && !stillSettling) {
        frozen = true;
        return;
    }
    rafHandle = requestAnimationFrame(tick);
}

function effectiveState(state, seasonDone) {
    if (state === 'dead') return 'dead';
    if (seasonDone) return 'returning';
    return state;
}

function currentFrame(p) {
    if (!p?.result?.frames?.length) return null;
    const idx = clamp(Math.floor(dayT), 0, p.result.frames.length - 1);
    return p.result.frames[idx];
}

// ─── Bird movement ─────────────────────────────────────────────────────────
function updateBird(bird, state, burrow, dt) {
    if (state === 'dead') return false;
    if (state === 'incubating' || state === 'returning') {
        bird.target.x = bird.home.x;
        bird.target.y = bird.home.y;
    } else { // foraging
        bird.wanderVel.x += (Math.random() - 0.5) * 65 * bird.wanderJitter * dt;
        bird.wanderVel.y += (Math.random() - 0.5) * 65 * bird.wanderJitter * dt;
        bird.wanderVel.x *= 0.92;
        bird.wanderVel.y *= 0.92;
        bird.wander.x += bird.wanderVel.x;
        bird.wander.y += bird.wanderVel.y;

        // Push out of island if it wandered onto land
        const dx = bird.wander.x - KENT_CX;
        const dy = bird.wander.y - KENT_CY;
        const islandFactor = Math.sqrt((dx / (KENT_RX * 1.2)) ** 2 + (dy / (KENT_RY * 1.2)) ** 2);
        if (islandFactor < 1) {
            const a = Math.atan2(dy, dx);
            const push = (1 - islandFactor) * 14;
            bird.wander.x += Math.cos(a) * push;
            bird.wander.y += Math.sin(a) * push;
        }
        bird.wander.x = clamp(bird.wander.x, 14, W - 14);
        bird.wander.y = clamp(bird.wander.y, 14, H - 14);

        bird.target.x = bird.wander.x;
        bird.target.y = bird.wander.y;
    }

    const lerpAmt = state === 'foraging' ? 0.10 : 0.18;
    const dxp = bird.target.x - bird.pos.x;
    const dyp = bird.target.y - bird.pos.y;
    bird.pos.x += dxp * lerpAmt;
    bird.pos.y += dyp * lerpAmt;

    if (Math.abs(dxp) + Math.abs(dyp) > 0.5) {
        // Moving — face the direction of motion
        bird.heading = Math.atan2(dyp, dxp);
    } else if (state === 'incubating' || state === 'returning') {
        // Settled at home — turn to face the egg
        const eggX = burrow.x;
        const eggY = burrow.y - 4;
        const ax = eggX - bird.pos.x;
        const ay = eggY - bird.pos.y;
        if (Math.abs(ax) + Math.abs(ay) > 0.1) {
            bird.heading = Math.atan2(ay, ax);
        }
    }

    const distSq = dxp * dxp + dyp * dyp;
    return state === 'foraging' || distSq > 0.4;
}

// ─── Drawing ──────────────────────────────────────────────────────────────
function drawAll() {
    if (!mainCtx) return;
    mainCtx.drawImage(baseMap, 0, 0);

    for (const p of pairs) {
        const f = currentFrame(p);
        if (!f) continue;
        drawBurrow(mainCtx, p.burrow.x, p.burrow.y);
        drawEgg(mainCtx, p.burrow.x, p.burrow.y - 4, f);
    }
    for (const p of pairs) {
        const f = currentFrame(p);
        if (!f) continue;
        drawPetrel(mainCtx, p.female.pos.x, p.female.pos.y, p.female.heading, 'female', f.femaleState);
        drawPetrel(mainCtx, p.male.pos.x,   p.male.pos.y,   p.male.heading,   'male',   f.maleState);
    }

    drawRibbon();
    drawReadouts();
}

function drawBurrow(ctx, bx, by) {
    // Dirt mound
    ctx.fillStyle = COL.burrowDirt;
    ctx.beginPath();
    ctx.ellipse(bx, by, 11, 7, 0, 0, Math.PI * 2);
    ctx.fill();
    // Mouth
    ctx.fillStyle = COL.burrowMouth;
    ctx.beginPath();
    ctx.ellipse(bx, by, 6, 4, 0, 0, Math.PI * 2);
    ctx.fill();
}

function drawEgg(ctx, ex, ey, f) {
    const c    = eggHealthColour(f);
    const dark = darken(c, 0.5);
    const light = lighten(c, 0.4);
    // Body
    ctx.fillStyle = c;
    ctx.beginPath();
    ctx.ellipse(ex, ey, 5.5, 7.5, 0, 0, Math.PI * 2);
    ctx.fill();
    // Highlight
    ctx.fillStyle = light;
    ctx.beginPath();
    ctx.ellipse(ex - 1.5, ey - 2.5, 1.6, 2.6, -0.4, 0, Math.PI * 2);
    ctx.fill();
    // Outline
    ctx.strokeStyle = dark;
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.ellipse(ex, ey, 5.5, 7.5, 0, 0, Math.PI * 2);
    ctx.stroke();
}

function eggHealthColour(f) {
    if (f.eggHatched) return '#22c55e';
    if (!f.eggAlive)  return '#7c2d12';
    const dangerFrac = Math.min(1, f.eggCurrNeg / 7);
    if (dangerFrac > 0.05) {
        return lerp3('#fde68a', '#f97316', '#dc2626', dangerFrac);
    }
    const progress = Math.min(1, f.day / Math.max(1, f.eggHatchDays));
    return lerpHex('#fde68a', '#86efac', progress);
}

// Top-down Leach's storm-petrel silhouette.
//
// In the local rotated frame:
//   +x  = forward (head),   −x  = tail
//   +y  = right wing,        −y  = left wing
//
// • Foraging birds are drawn with wings fully spread (long, swept-back).
// • Incubating / returning / settled birds are drawn with wings folded
//   close against the body — a much more compact silhouette.
// • Every bird shows a bright white rump patch at the base of the tail
//   (the field-mark that makes Leach's storm-petrels recognisable from
//   above) and a forked tail.
function drawPetrel(ctx, x, y, heading, sex, state) {
    if (state === 'dead') {
        ctx.strokeStyle = COL.deadBird;
        ctx.lineWidth = 2;
        ctx.beginPath();
        ctx.moveTo(x - 6, y - 6); ctx.lineTo(x + 6, y + 6);
        ctx.moveTo(x + 6, y - 6); ctx.lineTo(x - 6, y + 6);
        ctx.stroke();
        return;
    }

    const flying = state === 'foraging';
    const body   = sex === 'female' ? COL.f     : COL.m;
    const dark   = sex === 'female' ? COL.fDark : COL.mDark;

    ctx.save();
    ctx.translate(x, y);
    ctx.rotate(heading);

    if (flying) {
        // Wings spread — long, tapered, swept slightly back from the shoulder
        ctx.fillStyle = dark;
        // Right wing
        ctx.beginPath();
        ctx.moveTo(2.2, 1.6);
        ctx.bezierCurveTo( 3.5,  4.5, -0.5,  10, -3,  13.5);   // leading edge → wingtip
        ctx.bezierCurveTo(-3.5, 11.0, -3.0,  4.5, -3.2, 1.8); // trailing edge → body
        ctx.closePath();
        ctx.fill();
        // Left wing (mirror)
        ctx.beginPath();
        ctx.moveTo(2.2, -1.6);
        ctx.bezierCurveTo( 3.5, -4.5, -0.5, -10, -3, -13.5);
        ctx.bezierCurveTo(-3.5, -11.0, -3.0, -4.5, -3.2, -1.8);
        ctx.closePath();
        ctx.fill();
    }

    // Body — slender oval, sex-tinted
    ctx.fillStyle = body;
    ctx.beginPath();
    ctx.ellipse(0, 0, 4.6, 1.7, 0, 0, Math.PI * 2);
    ctx.fill();

    if (!flying) {
        // Folded wings: two dark covers running along the back of the body
        ctx.fillStyle = dark;
        ctx.beginPath();
        ctx.ellipse(-0.4,  1.2, 4.2, 1.0, -0.10, 0, Math.PI * 2);
        ctx.fill();
        ctx.beginPath();
        ctx.ellipse(-0.4, -1.2, 4.2, 1.0,  0.10, 0, Math.PI * 2);
        ctx.fill();
    }

    // Forked tail — drawn as one filled "bowtie" shape behind the body
    ctx.fillStyle = dark;
    ctx.beginPath();
    ctx.moveTo(-3.5, -0.7);
    ctx.lineTo(-9.5, -2.6);
    ctx.lineTo(-6.5,  0);
    ctx.lineTo(-9.5,  2.6);
    ctx.lineTo(-3.5,  0.7);
    ctx.closePath();
    ctx.fill();

    // White rump patch at the base of the tail — signature petrel field mark
    ctx.fillStyle = COL.rump;
    ctx.beginPath();
    ctx.ellipse(-3.4, 0, 2.0, 1.05, 0, 0, Math.PI * 2);
    ctx.fill();

    // Head + pointed beak (forward of the body)
    ctx.fillStyle = dark;
    ctx.beginPath();
    ctx.arc(4.6, 0, 1.55, 0, Math.PI * 2);
    ctx.fill();
    ctx.beginPath();
    ctx.moveTo(5.8, -0.45);
    ctx.lineTo(7.8,  0);
    ctx.lineTo(5.8,  0.45);
    ctx.closePath();
    ctx.fill();

    ctx.restore();
}

// ─── Coverage ribbon (stacked-state %) ─────────────────────────────────────
function drawRibbon() {
    const canvas = byId('replay-ribbon');
    const ctx = canvas.getContext('2d');
    const RW = canvas.width, RH = canvas.height;
    ctx.fillStyle = '#1f2630';
    ctx.fillRect(0, 0, RW, RH);

    if (!pairs.length) return;
    const days = maxSeasonLen();
    const cellW = RW / Math.max(1, days);

    for (let d = 0; d < days; d++) {
        let nF = 0, nM = 0, nN = 0, nHatched = 0, nFailed = 0;
        for (const p of pairs) {
            if (!p?.result?.frames) continue;
            if (d >= p.result.frames.length) {
                if (p.result.outcome === 'hatched') nHatched++;
                else nFailed++;
                continue;
            }
            const f = p.result.frames[d];
            if (!f) continue;
            if (f.femaleState === 'incubating')      nF++;
            else if (f.maleState === 'incubating')   nM++;
            else                                     nN++;
        }
        const total = pairs.length || 1;
        const segs = [
            [nF / total, '#f59e0b'],
            [nM / total, '#0ea5e9'],
            [nN / total, '#444'],
            [nHatched / total, '#2ecc71'],
            [nFailed / total, '#e84a4a'],
        ];
        let yy = 0;
        for (const [frac, col] of segs) {
            const segH = frac * RH;
            ctx.fillStyle = col;
            ctx.fillRect(d * cellW, yy, cellW + 0.6, segH + 0.6);
            yy += segH;
        }
    }

    const cx = (clamp(dayT, 0, days - 1) + 0.5) * cellW;
    ctx.fillStyle = 'rgba(255, 255, 255, 0.85)';
    ctx.fillRect(cx - 1, 0, 2, RH);
}

// ─── Population readouts ──────────────────────────────────────────────────
function drawReadouts() {
    const d = Math.max(0, Math.floor(dayT));
    let inProgress = 0, hatched = 0, eggDied = 0, parentLost = 0;
    let attended = 0;
    let fEnergySum = 0, fEnergyCount = 0;
    let mEnergySum = 0, mEnergyCount = 0;
    let negSum = 0, negCount = 0;

    for (const p of pairs) {
        if (!p?.result?.frames) continue;
        if (d >= p.result.frames.length) {
            switch (p.result.outcome) {
                case 'hatched': hatched++; break;
                case 'egg_died': eggDied++; break;
                case 'female_died':
                case 'male_died':
                case 'both_died': parentLost++; break;
                default: eggDied++;
            }
            continue;
        }
        const f = p.result.frames[d];
        if (!f) continue;
        inProgress++;
        if (f.femaleState === 'incubating' || f.maleState === 'incubating') attended++;
        if (f.femaleState !== 'dead') { fEnergySum += f.femaleEnergy; fEnergyCount++; }
        if (f.maleState   !== 'dead') { mEnergySum += f.maleEnergy;   mEnergyCount++; }
        negSum += f.eggCurrNeg; negCount++;
    }

    byId('r-day').textContent        = `${d}`;
    byId('r-active').textContent     = `${inProgress}`;
    byId('r-hatched').textContent    = `${hatched}`;
    byId('r-eggdied').textContent    = `${eggDied}`;
    byId('r-parentlost').textContent = `${parentLost}`;
    byId('r-attended').textContent   = inProgress
        ? `${Math.round(100 * attended / inProgress)}%` : '—';
    byId('r-fenergy').textContent    = fEnergyCount
        ? `${Math.round(fEnergySum / fEnergyCount)} kJ` : '—';
    byId('r-menergy').textContent    = mEnergyCount
        ? `${Math.round(mEnergySum / mEnergyCount)} kJ` : '—';
    byId('r-neg').textContent        = negCount
        ? (negSum / negCount).toFixed(2) : '0';
}

// ─── Utilities ────────────────────────────────────────────────────────────
function byId(id) { return document.getElementById(id); }
function clamp(v, lo, hi) { return v < lo ? lo : v > hi ? hi : v; }

function hexToRgb(hex) {
    const c = hex.replace('#', '');
    const n = parseInt(c, 16);
    return [(n >> 16) & 255, (n >> 8) & 255, n & 255];
}
function rgbToHex(r, g, b) {
    const c = (n) => Math.max(0, Math.min(255, Math.round(n))).toString(16).padStart(2, '0');
    return '#' + c(r) + c(g) + c(b);
}
function lerpHex(c1, c2, t) {
    const [r1, g1, b1] = hexToRgb(c1);
    const [r2, g2, b2] = hexToRgb(c2);
    return rgbToHex(r1 + (r2 - r1) * t, g1 + (g2 - g1) * t, b1 + (b2 - b1) * t);
}
function lerp3(c0, c1, c2, t) {
    if (t < 0.5) return lerpHex(c0, c1, t * 2);
    return lerpHex(c1, c2, (t - 0.5) * 2);
}
function darken(hex, amt) {
    const [r, g, b] = hexToRgb(hex);
    return rgbToHex(r * (1 - amt), g * (1 - amt), b * (1 - amt));
}
function lighten(hex, amt) {
    const [r, g, b] = hexToRgb(hex);
    return rgbToHex(r + (255 - r) * amt, g + (255 - g) * amt, b + (255 - b) * amt);
}
