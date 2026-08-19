// PROTOTYPE — throwaway. Builds ticket 15's artboards from fixture.json, so every number
// on every screen is the output of Fitty's real progression rules. Run: node build.mjs

import { readFileSync, writeFileSync } from 'node:fs';

const F = JSON.parse(readFileSync(new URL('./fixture.json', import.meta.url)));
const out = p => new URL('./' + p, import.meta.url);

// ---- the standard, from ticket 2 + ticket 11 --------------------------------------
const C = {
  floor: '#0E0F10', card: '#17191B', line: '#26292C', steel: '#9BA1A7',
  dim: '#8D9296', text: '#F4F1EC', green: '#2E9E52', faint: '#1E2123', label: '#55595D'
};

const CSS = `
:root{
  --floor:${C.floor}; --card:${C.card}; --line:${C.line}; --steel:${C.steel};
  --dim:${C.dim}; --text:${C.text}; --green:${C.green}; --label:${C.label};
  --display:Anton, Haettenschweiler, Impact, sans-serif;
  --body:'IBM Plex Sans', system-ui, sans-serif;
}
*{box-sizing:border-box}
body{margin:0;background:var(--floor);color:var(--text);font-family:var(--body);
     font-variant-numeric:tabular-nums;-webkit-font-smoothing:antialiased}
.screen{position:absolute;inset:0;padding:54px 20px 20px;display:flex;flex-direction:column;z-index:10}
.kicker{font-family:var(--display);font-size:13px;letter-spacing:.1em;text-transform:uppercase;color:var(--steel)}
.label{font-size:10px;letter-spacing:.14em;color:var(--label);text-transform:uppercase}
.rowbetween{display:flex;align-items:center;justify-content:space-between}
.back{font-size:13px;color:var(--steel);letter-spacing:.02em}
.dots{color:var(--steel);font-size:17px;letter-spacing:.06em}

/* the chart screen */
.exname{font-family:var(--display);font-size:25px;line-height:.94;letter-spacing:.02em;text-transform:uppercase;margin-top:16px}
.exmeta{font-size:11px;color:var(--dim);margin-top:7px;letter-spacing:.02em}
.hero{display:flex;align-items:baseline;gap:10px;margin-top:18px}
.hero .n{font-family:var(--display);font-size:58px;line-height:.78;letter-spacing:-.01em}
.hero .u{font-family:var(--display);font-size:21px;line-height:1;letter-spacing:.04em;color:var(--steel)}
.hero .l{font-size:9px;letter-spacing:.14em;color:var(--label);text-transform:uppercase;margin-left:auto;text-align:right;line-height:1.5}
.chip{display:inline-block;border:1px solid #41464A;color:var(--steel);border-radius:2px;
      padding:4px 8px;font-size:9.5px;letter-spacing:.12em;text-transform:uppercase;margin-top:14px}
.chip.up{border-color:${C.green};color:${C.green}}
.chartwrap{margin-top:18px}
.legend{display:flex;gap:14px;margin-top:12px;flex-wrap:wrap}
.leg{display:flex;align-items:center;gap:6px;font-size:9px;letter-spacing:.11em;color:var(--label);text-transform:uppercase}
.stats{border-top:1px solid var(--line);padding-top:12px;display:flex;margin-top:auto}
.stat{flex:1 1 0}
.stat .v{font-family:var(--display);font-size:19px;line-height:1;letter-spacing:.02em}
.stat .v.g{color:var(--green)}
.stat .l{font-size:9px;letter-spacing:.13em;color:var(--label);margin-top:5px;text-transform:uppercase}

/* lists */
.scroll{overflow-y:auto;flex:1 1 auto;margin-top:16px}
.scroll::-webkit-scrollbar{width:0}
.sec > .label{margin-bottom:10px;display:block}
.wrow{display:flex;gap:12px;align-items:flex-start;padding:13px 0;border-top:1px solid var(--line)}
.wrow:last-child{border-bottom:1px solid var(--line)}
.wdate{flex:0 0 46px;font-family:var(--display);font-size:15px;line-height:1;letter-spacing:.03em;color:var(--steel);text-transform:uppercase;padding-top:2px}
.wday{font-family:var(--display);font-size:16px;line-height:1;letter-spacing:.02em;text-transform:uppercase}
.wmeta{font-size:11px;color:var(--dim);margin-top:6px}
.wup{font-size:10px;letter-spacing:.11em;color:var(--green);margin-top:6px;text-transform:uppercase}
.chev{flex:0 0 auto;color:var(--label);font-size:13px;padding-top:2px}

/* streak */
.streak{border:1px solid var(--line);border-radius:3px;padding:16px 15px 14px;margin-top:16px}
.streak .n{font-family:var(--display);font-size:44px;line-height:.8;letter-spacing:-.01em}
.streak .c{font-family:var(--display);font-size:14px;line-height:1;letter-spacing:.05em;
           text-transform:uppercase;margin-top:9px;color:var(--text)}
.grid{display:flex;gap:3px;margin-top:15px}
.wk{flex:1 1 0;height:26px;border-radius:2px}
.wk.on{background:var(--steel)}
.wk.off{background:#191B1D}
.gridfoot{display:flex;justify-content:space-between;margin-top:8px}

/* exercise cards (program sheet) */
.card{border:1px solid var(--line);border-radius:3px;padding:13px 14px;margin-bottom:8px;display:flex;
      align-items:center;gap:12px}
.card .nm{font-family:var(--display);font-size:15px;line-height:1;letter-spacing:.02em;text-transform:uppercase}
.card .mt{font-size:11px;color:var(--dim);margin-top:6px}
.spark{flex:0 0 auto}

/* set table */
.setrow{display:flex;align-items:center;gap:0;padding:0 0;height:44px;border-top:1px solid var(--faint)}
.setrow .i{flex:0 0 26px;font-size:11px;color:var(--label)}
.setrow .r{font-family:var(--display);font-size:19px;line-height:1;letter-spacing:.02em;flex:0 0 54px}
.setrow .rl{font-size:9px;letter-spacing:.13em;color:var(--label);text-transform:uppercase;flex:0 0 42px}
.setrow .w{font-size:13px;color:#C9CDD1;margin-left:auto}
.exhead{display:flex;align-items:baseline;justify-content:space-between;margin-top:20px;margin-bottom:2px}
.exhead .nm{font-family:var(--display);font-size:16px;line-height:1;letter-spacing:.02em;text-transform:uppercase}
.exhead .st{font-size:10px;letter-spacing:.12em;color:var(--label);text-transform:uppercase}
.exhead .st.up{color:var(--green)}
.oneoff{display:inline-block;border:1px solid #41464A;color:var(--steel);border-radius:2px;
        padding:2px 6px;font-size:9px;letter-spacing:.12em;text-transform:uppercase}

/* sheet */
.scrim{position:absolute;inset:0;background:rgba(6,7,8,.72);z-index:20}
.sheet{position:absolute;left:0;right:0;bottom:0;background:#131517;border-top:1px solid var(--line);
       border-radius:3px 3px 0 0;padding:24px 20px 22px;z-index:30}
.sheet h1{font-family:var(--display);font-size:22px;line-height:1;letter-spacing:.03em;
          text-transform:uppercase;margin:0 0 14px}
.sheet p{font-size:13px;line-height:1.6;color:#C9CDD1;margin:0 0 10px}
.sheet p.keep{color:var(--steel)}
.btns{display:flex;gap:10px;margin-top:20px}
.btn{flex:1 1 0;height:56px;border:1px solid var(--line);border-radius:3px;background:transparent;
     color:var(--text);font-family:var(--display);font-size:16px;letter-spacing:.06em;text-transform:uppercase}
.btn.danger{background:#C8322B;border-color:#C8322B;color:#0E0F10}
.bmain{width:100%;height:64px;border:0;border-radius:3px;background:var(--text);color:#0E0F10;
       font-family:var(--display);font-size:20px;letter-spacing:.06em;text-transform:uppercase;margin-top:14px}
.empty{flex:1 1 auto;display:flex;flex-direction:column;justify-content:center;align-items:flex-start}
.empty .h{font-family:var(--display);font-size:26px;line-height:.96;letter-spacing:.02em;text-transform:uppercase}
.empty .p{font-size:13px;line-height:1.65;color:var(--dim);margin-top:12px}
`;

// ---- chart -------------------------------------------------------------------------
// One series, drawn in steel. No plate colour ever enters a chart: on the loaded bar,
// colour plus size means weight, and a line that borrowed a plate hue would claim to be
// one. Green is the single exception, because ticket 2 already made green mean
// progression everywhere in Fitty.

const DAY = 86400000;
const MONTHS = ['JAN','FEB','MAR','APR','MAY','JUN','JUL','AUG','SEP','OCT','NOV','DEC'];

function series(key) {
  const ex = F.exercises.find(e => e.key === key);
  const pts = [];
  for (const w of F.workouts) {
    const e = w.exercises.find(x => x.key === key);
    if (!e || e.state === 'skipped') continue;          // a Skipped Exercise logs no Sets
    pts.push({
      t: Date.parse(w.date), label: w.label, date: w.date,
      weight: e.weight, microload: e.microload,
      shown: ex.key === 'pull' ? e.microload : e.weight, // the mixed-unit chart plots the Microload
      performed: e.oneOff ? e.oneOffWeight : e.weight,
      oneOff: e.oneOff, progressed: e.progressed,
      sets: e.sets.map(s => s.reps), repMax: e.repMax, repMin: e.repMin, mode: e.mode
    });
  }
  return { ex, pts };
}

// Renders the line chart as inline SVG. `mode` picks how the reps are shown:
//   'labels' — the top Set's reps as a figure over every point (the option the user picked)
//   'grid'   — a Set grid under the line: one column per session, one cell per Set
function chart({ pts, w = 350, h = 186, mode = 'grid', plot = p => p.performed, next = null, axis = '' }) {
  const padL = 36, padR = 34, padT = mode === 'labels' ? 26 : 14, padB = 22;
  const gridH = mode === 'grid' ? 34 : 0;
  const H = h + gridH;
  const iw = w - padL - padR, ih = h - padT - padB;

  const vals = pts.flatMap(p => [plot(p), p.weight]).concat(next == null ? [] : [next]);
  let lo = Math.min(...vals), hi = Math.max(...vals);
  const pad = (hi - lo) * 0.18 || 1;
  lo -= pad; hi += pad;

  // The x axis is real time, not the session number: a missed week shows as a wider gap,
  // and a Skipped Exercise simply has no point there. The dashed NEXT step to the right
  // needs room, so the last session sits short of the right edge.
  const t0 = pts[0].t, t1 = pts.at(-1).t;
  const hasNext = next != null && Math.abs(next - pts.at(-1).weight) > 1e-9;
  const usable = hasNext ? iw - 26 : iw;
  const X = t => padL + ((t - t0) / (t1 - t0)) * usable;
  const Y = v => padT + ih - ((v - lo) / (hi - lo)) * ih;

  // y ticks: clean weight steps, 4 at most
  const span = hi - lo;
  const step = [1, 2.5, 5, 10, 20, 25].find(s => span / s <= 4.5) || 50;
  const ticks = [];
  for (let v = Math.ceil(lo / step) * step; v <= hi; v += step) ticks.push(Math.round(v * 100) / 100);

  let s = `<svg width="${w}" height="${H}" viewBox="0 0 ${w} ${H}" fill="none" xmlns="http://www.w3.org/2000/svg" font-family="'IBM Plex Sans', system-ui, sans-serif">`;

  // gridlines — hairline, solid, recessive
  for (const v of ticks) {
    s += `<line x1="${padL}" y1="${Y(v).toFixed(1)}" x2="${w - padR}" y2="${Y(v).toFixed(1)}" stroke="${C.faint}" stroke-width="1"/>`;
    s += `<text x="${padL - 8}" y="${(Y(v) + 3.5).toFixed(1)}" text-anchor="end" font-size="9.5" fill="${C.label}" letter-spacing=".04em">${v}</text>`;
  }
  if (axis) s += `<text x="${padL - 8}" y="${padT - 3}" text-anchor="end" font-size="8.5" fill="${C.label}" letter-spacing=".1em">${axis}</text>`;

  // the line: the Working Weight, which is what Fitty tracks and what progression moves.
  // A One-off Weight is never on it, so the line never dips.
  const d = pts.map((p, i) => `${i ? 'L' : 'M'}${X(p.t).toFixed(1)} ${Y(p.weight).toFixed(1)}`).join(' ');
  s += `<path d="${d}" stroke="${C.steel}" stroke-width="2" stroke-linejoin="round" stroke-linecap="round"/>`;

  // Solid is lifted; dashed is not lifted yet. Fitty applies the progression at Finish, so
  // the weight on the Exercise card can already be one step above the last session. The
  // dashed step says so instead of letting the hero contradict the end of the line.
  if (hasNext) {
    const x0 = X(pts.at(-1).t), x1 = padL + iw, y0 = Y(pts.at(-1).weight), y1 = Y(next);
    s += `<path d="M${x0.toFixed(1)} ${y0.toFixed(1)} L${x1.toFixed(1)} ${y1.toFixed(1)}" stroke="${C.green}" stroke-width="2" stroke-dasharray="3 3" stroke-linecap="round"/>`;
    s += `<circle cx="${x1.toFixed(1)}" cy="${y1.toFixed(1)}" r="6" fill="${C.floor}"/>`;
    s += `<circle cx="${x1.toFixed(1)}" cy="${y1.toFixed(1)}" r="4" fill="${C.floor}" stroke="${C.green}" stroke-width="1.8"/>`;
    s += `<text x="${x1.toFixed(1)}" y="${(y1 - 11).toFixed(1)}" text-anchor="end" font-size="8.5" fill="${C.green}" letter-spacing=".13em">NEXT</text>`;
  }

  // month ticks on the x axis
  let lastMonth = -1;
  for (const p of pts) {
    const m = new Date(p.t).getUTCMonth();
    if (m !== lastMonth) {
      lastMonth = m;
      s += `<text x="${X(p.t).toFixed(1)}" y="${h - 4}" text-anchor="middle" font-size="9" fill="${C.label}" letter-spacing=".13em">${MONTHS[m]}</text>`;
    }
  }

  // One-off Weights: off the line, hollow, on their own height, with a steel tie to the
  // session they belong to. Hollow says "Fitty logged this, but it never became the
  // Working Weight" — the line above it is still the truth.
  for (const p of pts) {
    if (!p.oneOff) continue;
    const x = X(p.t), yw = Y(p.weight), yo = Y(p.performed);
    s += `<line x1="${x.toFixed(1)}" y1="${yw.toFixed(1)}" x2="${x.toFixed(1)}" y2="${yo.toFixed(1)}" stroke="#3A3F43" stroke-width="1" stroke-dasharray="2 3"/>`;
    s += `<circle cx="${x.toFixed(1)}" cy="${yo.toFixed(1)}" r="4" fill="${C.floor}" stroke="${C.steel}" stroke-width="1.6"/>`;
    s += `<text x="${(x + 9).toFixed(1)}" y="${(yo + 3.5).toFixed(1)}" font-size="8.5" fill="${C.steel}" letter-spacing=".13em">ONE-OFF</text>`;
  }

  // session markers. A 2px floor ring keeps them legible where they sit on the line.
  for (const p of pts) {
    const x = X(p.t), y = Y(p.weight);
    const c = p.progressed ? C.green : C.steel;
    const r = p.progressed ? 4 : 3.2;
    s += `<circle cx="${x.toFixed(1)}" cy="${y.toFixed(1)}" r="${r + 2}" fill="${C.floor}"/>`;
    s += `<circle cx="${x.toFixed(1)}" cy="${y.toFixed(1)}" r="${r}" fill="${c}"/>`;
  }

  if (mode === 'labels') {
    // Reps as a figure over every point: the best Set of that session.
    for (const p of pts) {
      const x = X(p.t), y = Y(p.weight);
      const best = Math.max(...p.sets);
      const hit = p.sets.every(v => v >= (p.mode === 'microloading' ? p.repMin : p.repMax));
      s += `<text x="${x.toFixed(1)}" y="${(y - 11).toFixed(1)}" text-anchor="middle" font-size="9.5"
              fill="${hit ? C.green : C.dim}" letter-spacing=".02em">${best}</text>`;
    }
  } else {
    // The Set grid: one column per session, one cell per Set, filled where the Set met the
    // threshold of its Progression Mode. Three filled cells is exactly the progression rule,
    // so the grid answers "why did it not go up" without a word of advice.
    const gy = h + 6, cell = 7, gap = 2.5;
    for (const p of pts) {
      const x = X(p.t);
      const th = p.mode === 'microloading' ? p.repMin : p.repMax;
      p.sets.forEach((v, i) => {
        const cy = gy + i * (cell + gap);
        // A One-off Weight never progresses, whatever the reps. Filling its cells green
        // would draw a full column beside a step that never came.
        const met = v >= th && !p.oneOff;
        s += met
          ? `<rect x="${(x - cell / 2).toFixed(1)}" y="${cy}" width="${cell}" height="${cell}" rx="1.5" fill="${C.green}"/>`
          : `<rect x="${(x - cell / 2 + .5).toFixed(1)}" y="${cy + .5}" width="${cell - 1}" height="${cell - 1}" rx="1.5" fill="none" stroke="#3A3F43" stroke-width="1"/>`;
      });
    }
    s += `<text x="${padL - 8}" y="${gy + 12}" text-anchor="end" font-size="8.5" fill="${C.label}" letter-spacing=".1em">SETS</text>`;
  }

  return s + '</svg>';
}

// a 54×20 sparkline for an Exercise card in the Program sheet
function spark(pts) {
  const w = 54, h = 20, vals = pts.map(p => p.weight);
  const lo = Math.min(...vals), hi = Math.max(...vals) || 1;
  const X = i => (i / (pts.length - 1)) * (w - 2) + 1;
  const Y = v => h - 3 - ((v - lo) / ((hi - lo) || 1)) * (h - 6);
  const d = pts.map((p, i) => `${i ? 'L' : 'M'}${X(i).toFixed(1)} ${Y(p.weight).toFixed(1)}`).join(' ');
  return `<svg class="spark" width="${w}" height="${h}" fill="none" xmlns="http://www.w3.org/2000/svg">`
    + `<path d="${d}" stroke="${C.steel}" stroke-width="1.5" stroke-linejoin="round" stroke-linecap="round"/>`
    + `<circle cx="${X(pts.length - 1).toFixed(1)}" cy="${Y(vals.at(-1)).toFixed(1)}" r="2.2" fill="${C.steel}"/></svg>`;
}

// ---- page shell --------------------------------------------------------------------
function page(body) {
  return `<!doctype html>
<html>
<head>
  <meta charset="utf-8">
  <script src="./support.js"></script>
</head>
<body>
<x-dc>
<helmet>
  <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Anton&family=IBM+Plex+Sans:wght@400;500;600&display=swap">
  <style>${CSS}</style>
</helmet>
<div style="position: relative; width: 390px; height: 844px; overflow: hidden; background: ${C.floor};">
${body}
</div>
</x-dc>
</body>
</html>
`;
}

const nf = n => (Math.round(n * 100) / 100).toString();

// ---- 1. the chart screens ----------------------------------------------------------
function chartScreen({ key, mode, title }) {
  const { ex, pts } = series(key);
  const last = pts.at(-1);
  // The hero is the weight the Exercise carries NOW, not the weight last performed.
  // Fitty applies the progression at Finish, so after a session that went up the two differ.
  const cur = F.current[key].weight;
  const first = pts[0].weight;
  const th = ex.mode === 'microloading' ? ex.repMin : ex.repMax;

  // The condition, stated — the same rule chip the logging screen shows. Always the
  // condition, never a celebration: the weight above it is already the new one.
  const chip = `<div class="chip">All ${ex.sets} sets at ${th} → ${nf(cur + ex.increment)} kg</div>`;

  const svg = chart({ pts, mode, next: cur });
  const legend = mode === 'grid'
    ? `<div class="legend">
         <div class="leg"><svg width="10" height="10"><circle cx="5" cy="5" r="4" fill="${C.green}"/></svg>Went up</div>
         <div class="leg"><svg width="10" height="10"><circle cx="5" cy="5" r="3.2" fill="${C.steel}"/></svg>Stayed</div>
         <div class="leg"><svg width="10" height="10"><circle cx="5" cy="5" r="4" fill="${C.floor}" stroke="${C.steel}" stroke-width="1.6"/></svg>One-off</div>
         <div class="leg"><svg width="10" height="10"><rect x="1.5" y="1.5" width="7" height="7" rx="1.5" fill="${C.green}"/></svg>Set at ${th}</div>
       </div>`
    : `<div class="legend">
         <div class="leg"><svg width="10" height="10"><circle cx="5" cy="5" r="4" fill="${C.green}"/></svg>Went up</div>
         <div class="leg"><svg width="10" height="10"><circle cx="5" cy="5" r="3.2" fill="${C.steel}"/></svg>Stayed</div>
         <div class="leg"><svg width="10" height="10"><circle cx="5" cy="5" r="4" fill="${C.floor}" stroke="${C.steel}" stroke-width="1.6"/></svg>One-off</div>
         <div class="leg">Figure = best set</div>
       </div>`;

  const ups = pts.filter(p => p.progressed).length;

  // The grid abstracts the reps to met / not met. The list under it carries the exact
  // numbers for the sessions the user can still remember, so nothing is only in a picture.
  const recent = [...pts].reverse().slice(0, 4).map(p => {
    const met = p.sets.every(v => v >= th) && !p.oneOff;
    return `<div class="setrow" style="height:40px">
      <div class="i" style="flex:0 0 52px;color:${C.steel}">${p.label}</div>
      <div style="font-size:14px;color:${met ? C.green : '#C9CDD1'};letter-spacing:.06em">${p.sets.join(' · ')}</div>
      <div class="w" style="display:flex;align-items:center;gap:8px">
        ${p.oneOff ? `<span class="oneoff">One-off</span>` : ''}
        <span>${nf(p.oneOff ? p.performed : p.weight)} kg</span>
      </div>
    </div>`;
  }).join('');

  return page(`<div class="screen">
  <div class="rowbetween"><div class="back">‹ ${EQ_DAY[key] || 'Upper A'}</div><div class="dots">•••</div></div>
  <div class="exname">${ex.name}</div>
  <div class="exmeta">${EQ[ex.equipment]} · ${ex.sets} × ${ex.repMin}–${ex.repMax} · ${ex.mode === 'microloading' ? 'Microloading' : 'Progressive overload'}</div>
  <div class="hero"><div class="n">${nf(cur)}</div><div class="u">kg</div>
    <div class="l">Working<br>weight</div></div>
  ${chip}
  <div class="chartwrap">${svg}</div>
  ${legend}
  <div style="margin-top:16px"><span class="label">Last sessions</span></div>
  <div style="margin-top:6px">${recent}</div>
  <div class="stats">
    <div class="stat"><div class="v">${nf(first)} kg</div><div class="l">On ${pts[0].label}</div></div>
    <div class="stat"><div class="v g">+${nf(cur - first)} kg</div><div class="l">Since then</div></div>
    <div class="stat"><div class="v">${ups}</div><div class="l">Times up</div></div>
  </div>
</div>`);
}

const EQ = { smith: 'Smith machine', barbell: 'Barbell', dumbbell: 'Dumbbell',
             stack: 'Machine (stack)', cable: 'Cable', bodyweight: 'Bodyweight', plate: 'Plate-loaded' };
const EQ_DAY = { smith: 'Upper A', row: 'Upper A', pull: 'Upper A', press: 'Upper A', chin: 'Upper A' };

writeFileSync(out('Main.dc.html'), chartScreen({ key: 'smith', mode: 'grid' }));
writeFileSync(out('ChartLabels.dc.html'), chartScreen({ key: 'smith', mode: 'labels' }));
writeFileSync(out('Plateau.dc.html'), chartScreen({ key: 'press', mode: 'grid' }));

// ---- 2. the mixed-unit chart -------------------------------------------------------
// Lat pulldown is an lbs stack with a kg Microplate on the pin. The two units never
// convert, so there is no single number to plot: the Working Weight has not moved in 15
// weeks, and every gram of the climb is in the Microload.
{
  const { ex, pts } = series('pull');
  // The two units never convert, so there is no single number to plot. The pin has not
  // moved in 15 weeks; every gram of the climb is in the Microload, so the Microload is
  // what the line plots — and the axis says so, in its own unit.
  const pts2 = pts.map(p => ({ ...p, weight: p.microload, performed: p.microload }));
  const curMicro = F.current.pull.microload;
  const svg2 = chart({ pts: pts2, mode: 'grid', next: curMicro, axis: '+ KG' });
  writeFileSync(out('Mixed.dc.html'), page(`<div class="screen">
  <div class="rowbetween"><div class="back">‹ Upper A</div><div class="dots">•••</div></div>
  <div class="exname">${ex.name}</div>
  <div class="exmeta">Machine (stack) · ${ex.sets} × ${ex.repMin}–${ex.repMax} · Microloading</div>
  <div class="hero" style="margin-top:16px"><div class="n" style="font-size:46px">90</div><div class="u">lbs</div>
    <div class="l">Pin</div></div>
  <div class="hero" style="margin-top:10px"><div class="n" style="font-size:46px">+ ${nf(curMicro)}</div><div class="u">kg</div>
    <div class="l">Microload<br>on the pin</div></div>
  <div class="chip">All 3 sets at 10 → + ${nf(curMicro + 0.25)} kg</div>
  <div class="chartwrap">${svg2}</div>
  <div class="legend">
    <div class="leg" style="text-transform:none;letter-spacing:0;font-size:11px;color:${C.dim};line-height:1.5">
      The line is the microload. The pin has not moved in 15 weeks, so the pin is not on it.
      Nothing here converts.</div>
  </div>
  <div style="margin-top:14px"><span class="label">Last sessions</span></div>
  <div style="margin-top:6px">${[...pts].reverse().slice(0, 3).map(p => `<div class="setrow" style="height:40px">
      <div class="i" style="flex:0 0 52px;color:${C.steel}">${p.label}</div>
      <div style="font-size:14px;color:${p.sets.every(v => v >= ex.repMin) ? C.green : '#C9CDD1'};letter-spacing:.06em">${p.sets.join(' · ')}</div>
      <div class="w">90 lbs + ${nf(p.microload)} kg</div>
    </div>`).join('')}</div>
  <div class="stats">
    <div class="stat"><div class="v">90 lbs</div><div class="l">Pin, unchanged</div></div>
    <div class="stat"><div class="v g">+${nf(curMicro)} kg</div><div class="l">On the pin</div></div>
    <div class="stat"><div class="v">${pts.filter(p => p.progressed).length}</div><div class="l">Times up</div></div>
  </div>
</div>`));
}

// ---- 3. history: streak + workout list ---------------------------------------------
{
  const wks = F.weeks;
  const grid = wks.map(w => `<div class="wk ${w.on ? 'on' : 'off'}"></div>`).join('');
  const rows = [...F.workouts].reverse().map(w => {
    const done = w.exercises.filter(e => e.state !== 'skipped');
    const ups = done.filter(e => e.progressed);
    const sets = done.reduce((n, e) => n + e.sets.length, 0);
    const skipped = w.exercises.length - done.length;
    const [d, m] = w.label.split(' ');
    return `<div class="wrow">
      <div class="wdate">${d}<br><span style="font-size:10px;color:${C.label}">${m}</span></div>
      <div style="flex:1 1 auto;min-width:0">
        <div class="wday">${w.day}</div>
        <div class="wmeta">${done.length} exercises · ${sets} sets${skipped ? ` · ${skipped} skipped` : ''}</div>
        ${ups.length ? `<div class="wup">${ups.length} went up</div>` : ''}
      </div>
      <div class="chev">›</div>
    </div>`;
  }).join('');

  writeFileSync(out('History.dc.html'), page(`<div class="screen">
  <div class="rowbetween"><div class="back">‹ Upper / Lower</div><div class="label">History</div></div>
  <div class="streak">
    <div class="n">${F.streak}</div>
    <div class="c">Weeks in a row</div>
    <div class="grid">${grid}</div>
    <div class="gridfoot"><span class="label">${wks[0].label}</span><span class="label">${wks.at(-1).label}</span></div>
  </div>
  <div class="scroll"><div class="sec"><span class="label">${F.workouts.length} workouts</span>${rows}</div></div>
</div>`));
}

// ---- 4. one past Workout, opened ---------------------------------------------------
{
  // the Workout that carries the One-off Weight — the case worth showing in the detail
  const w = F.workouts.find(x => x.exercises.some(e => e.oneOff));
  const blocks = w.exercises.map(e => {
    if (e.state === 'skipped') {
      return `<div class="exhead"><div class="nm">${e.name}</div><div class="st">Skipped</div></div>
              <div class="wmeta" style="margin-top:8px">No sets logged.</div>`;
    }
    const th = e.mode === 'microloading' ? e.repMin : e.repMax;
    const sets = e.sets.map((s, i) => `<div class="setrow">
        <div class="i">${i + 1}</div>
        <div class="r" style="color:${s.reps >= th ? C.green : C.text}">${s.reps}</div>
        <div class="rl">Reps</div>
        <div class="w">${nf(s.weight)} ${s.unit}${s.microload ? ` + ${nf(s.microload)} kg` : ''}</div>
      </div>`).join('');
    // A One-off row says it once: the chip already carries "the working weight stayed",
    // so the right-hand column would only repeat it.
    return `<div class="exhead"><div class="nm">${e.name}</div>
      <div class="st ${e.progressed ? 'up' : ''}">${e.progressed ? `${nf(e.from.weight)} → ${nf(e.to.weight)} kg` : e.oneOff ? '' : 'Stayed'}</div></div>
      ${e.oneOff ? `<div style="margin:8px 0 2px"><span class="oneoff">One-off · ${nf(e.weight)} kg stayed</span></div>` : ''}
      ${sets}`;
  }).join('');

  const totalSets = w.exercises.reduce((n, e) => n + e.sets.length, 0);
  const body = `<div class="screen">
  <div class="rowbetween"><div class="back">‹ History</div><div class="dots">•••</div></div>
  <div class="exname">${w.day}</div>
  <div class="exmeta">${w.label} 2026 · ${w.exercises.filter(e => e.state !== 'skipped').length} exercises · ${totalSets} sets</div>
  <div class="scroll">${blocks}</div>
</div>`;
  writeFileSync(out('Workout.dc.html'), page(body));

  // the delete confirm, over the same screen
  writeFileSync(out('Delete.dc.html'), page(`${body}
  <div class="scrim"></div>
  <div class="sheet">
    <h1>Delete this workout?</h1>
    <p>This removes ${w.exercises.filter(e => e.state !== 'skipped').length} exercises and ${totalSets} sets from your history.</p>
    <p class="keep">Your working weights stay where they are.</p>
    <div class="btns"><button class="btn">Cancel</button><button class="btn danger">Delete</button></div>
  </div>`));
}

// ---- 5. the two doors --------------------------------------------------------------
{
  const TODAY = Date.parse('2026-08-19');
  const days = F.days.map((n, i) => {
    const last = [...F.workouts].reverse().find(w => w.dayIndex === i);
    const ago = Math.round((TODAY - Date.parse(last.date)) / 86400000);
    return `<div class="card"><div style="flex:1 1 auto">
      <div class="nm">${n}</div><div class="mt">${ago === 1 ? 'Yesterday' : `${ago} days ago`}</div></div><div class="chev">›</div></div>`;
  }).join('');

  writeFileSync(out('Home.dc.html'), page(`<div class="screen">
  <div class="rowbetween"><div class="kicker">Upper / Lower</div><div class="dots">•••</div></div>
  <div style="margin-top:22px"><span class="label">Pick a day</span></div>
  <div style="margin-top:12px">${days}</div>
  <div style="margin-top:auto">
    <div class="card" style="margin-bottom:0">
      <div style="flex:1 1 auto">
        <div class="nm">History</div>
        <div class="mt">${F.workouts.length} workouts · ${F.streak} weeks in a row</div>
      </div>
      <div class="chev">›</div>
    </div>
  </div>
</div>`));

  const cards = F.exercises.filter(e => e.day === 0).map(e => {
    const { pts } = series(e.key);
    const now = F.current[e.key];   // what the Exercise carries now, not what it last lifted
    const val = e.key === 'pull' ? `90 lbs + ${nf(now.microload)} kg` : `${nf(now.weight)} kg`;
    const pl = e.key === 'pull' ? pts.map(p => ({ weight: p.microload })) : pts;
    return `<div class="card">
      <div style="flex:1 1 auto;min-width:0">
        <div class="nm">${e.name}</div>
        <div class="mt">${val} · ${e.sets} × ${e.repMin}–${e.repMax}</div>
      </div>
      ${spark(pl)}
      <div class="chev">›</div>
    </div>`;
  }).join('');

  writeFileSync(out('Program.dc.html'), page(`<div class="screen">
  <div class="rowbetween"><div class="back">‹ Upper / Lower</div><div class="dots">•••</div></div>
  <div class="exname">Upper A</div>
  <div class="exmeta">${F.exercises.filter(e => e.day === 0).length} exercises</div>
  <div class="scroll" style="margin-top:20px">${cards}</div>
</div>`));
}

// ---- 6. the empty state ------------------------------------------------------------
writeFileSync(out('Empty.dc.html'), page(`<div class="screen">
  <div class="rowbetween"><div class="back">‹ Upper / Lower</div><div class="label">History</div></div>
  <div class="empty">
    <div class="h">Nothing here yet</div>
    <div class="p">Finish your first workout and it lands here.<br>
      Every exercise gets a line as soon as it has two.</div>
  </div>
</div>`));

console.log('artboards written');
