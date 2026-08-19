// PROTOTYPE — throwaway. Generates the history fixture for ticket 15's artboards by
// running Fitty's real progression rules forward over the logging prototype's program.
// No invented curves: every weight on every chart is the output of these rules.

import { writeFileSync } from 'node:fs';

// ---- the rules, lifted from design/0007-logging/fitty-workout-logging.html --------
const round = n => Math.round(n * 1000) / 1000;
const threshold = ex => (ex.mode === 'microloading' ? ex.repMin : ex.repMax);

// An Exercise progresses only when it logged at least the planned Sets, every Set met
// the threshold of its Progression Mode, and it was not performed at a One-off Weight.
function progresses(ex, sets, oneOff) {
  if (oneOff != null) return false;
  if (sets.length < ex.sets) return false;
  return sets.every(s => s.reps >= threshold(ex));
}

// ---- the program (design/0007-logging fixture, extended to all four Workout Days) --
// The logging prototype only ever needed Upper A. A history screen needs the whole
// Program, or the Workout list reads "Upper A" fifteen times and the streak counts a
// one-day week. The five Upper A Exercises are unchanged; the rest follow the same rules.
const PROGRAM = { name: 'Upper / Lower', defaultUnit: 'kg' };

const EXERCISES = [
  { key: 'smith',  name: 'Smith machine bench press', equipment: 'smith',     unit: 'kg',
    start: 65,  sets: 3, repMin: 8,  repMax: 12, mode: 'progressive-overload', increment: 2.5, base: 15 },
  { key: 'row',    name: 'Barbell row',               equipment: 'barbell',   unit: 'kg',
    start: 52.5, sets: 3, repMin: 8, repMax: 10, mode: 'progressive-overload', increment: 2.5, base: 20 },
  { key: 'pull',   name: 'Lat pulldown',              equipment: 'stack',     unit: 'lbs',
    // 0.25 kg microplate: 15 weeks of Microloading lands under one 10 lbs Stack Step.
    // With the 1 kg plate the same rules run the Microload to +11 kg, which no pin carries —
    // the model has no rule that rolls a Microload up into the pin. See the ticket resolution.
    start: 90,  sets: 3, repMin: 10, repMax: 12, mode: 'microloading', microplate: 0.25, microplateUnit: 'kg',
    stackStep: 10 },
  { key: 'press',  name: 'Dumbbell shoulder press',   equipment: 'dumbbell',  unit: 'kg',
    start: 20,  sets: 3, repMin: 8,  repMax: 12, mode: 'progressive-overload', increment: 2.5 },
  { key: 'chin',   name: 'Weighted chin-up',          equipment: 'bodyweight', unit: 'kg',
    start: 10,  sets: 3, repMin: 6,  repMax: 8,  mode: 'progressive-overload', increment: 2.5 },

  // Lower A
  { key: 'squat',  name: 'Barbell back squat', equipment: 'barbell', unit: 'kg', day: 1,
    start: 80, sets: 3, repMin: 5, repMax: 8, mode: 'progressive-overload', increment: 5, base: 20 },
  { key: 'rdl',    name: 'Romanian deadlift',  equipment: 'barbell', unit: 'kg', day: 1,
    start: 70, sets: 3, repMin: 8, repMax: 10, mode: 'progressive-overload', increment: 2.5, base: 20 },
  { key: 'legcurl',name: 'Leg curl',           equipment: 'stack',   unit: 'lbs', day: 1,
    start: 70, sets: 3, repMin: 10, repMax: 12, mode: 'progressive-overload', increment: 10, stackStep: 10 },
  { key: 'calf',   name: 'Standing calf raise',equipment: 'smith',   unit: 'kg', day: 1,
    start: 60, sets: 4, repMin: 10, repMax: 15, mode: 'progressive-overload', increment: 2.5, base: 15 },

  // Upper B
  { key: 'ohp',    name: 'Overhead press',     equipment: 'barbell', unit: 'kg', day: 2,
    start: 40, sets: 3, repMin: 5, repMax: 8, mode: 'microloading', microplate: 0.5, microplateUnit: 'kg' },
  { key: 'dbrow',  name: 'Dumbbell row',       equipment: 'dumbbell',unit: 'kg', day: 2,
    start: 30, sets: 3, repMin: 8, repMax: 12, mode: 'progressive-overload', increment: 2.5 },
  { key: 'dip',    name: 'Weighted dip',       equipment: 'bodyweight', unit: 'kg', day: 2,
    start: 10, sets: 3, repMin: 6, repMax: 10, mode: 'progressive-overload', increment: 2.5 },
  { key: 'facepull',name:'Face pull',          equipment: 'cable',   unit: 'lbs', day: 2,
    start: 40, sets: 3, repMin: 12, repMax: 15, mode: 'progressive-overload', increment: 10, stackStep: 10 },
  { key: 'curl',   name: 'Barbell curl',       equipment: 'barbell', unit: 'kg', day: 2,
    start: 30, sets: 3, repMin: 8, repMax: 12, mode: 'microloading', microplate: 0.5, microplateUnit: 'kg' },

  // Lower B
  { key: 'front',  name: 'Front squat',        equipment: 'barbell', unit: 'kg', day: 3,
    start: 60, sets: 3, repMin: 5, repMax: 8, mode: 'progressive-overload', increment: 2.5, base: 20 },
  { key: 'legpress',name:'Leg press',          equipment: 'plate',   unit: 'kg', day: 3,
    start: 120, sets: 3, repMin: 8, repMax: 12, mode: 'progressive-overload', increment: 5, base: 25 },
  { key: 'legext', name: 'Leg extension',      equipment: 'stack',   unit: 'lbs', day: 3,
    start: 80, sets: 3, repMin: 10, repMax: 15, mode: 'progressive-overload', increment: 10, stackStep: 10 },
  { key: 'seatedcalf',name:'Seated calf raise',equipment: 'plate',   unit: 'kg', day: 3,
    start: 40, sets: 4, repMin: 10, repMax: 15, mode: 'progressive-overload', increment: 2.5, base: 10 }
];
EXERCISES.forEach(e => { if (e.day == null) e.day = 0; });

const DAYS = ['Upper A', 'Lower A', 'Upper B', 'Lower B'];
const DAY_OFFSET = [0, 1, 3, 4];   // Mon, Tue, Thu, Fri inside the same week

// ---- how the lifter performs -------------------------------------------------------
// A lifter is not a metronome. Two forces shape a session: how new the weight still is
// (sessions since the last jump), and the day itself — sleep, food, work. The second one
// is what puts plateaus in the data, and a chart with no plateau proves nothing.
// Deterministic, so the artboards are stable across runs.
function rng(seed) { let s = seed >>> 0; return () => (s = (s * 1664525 + 1013904223) >>> 0) / 2 ** 32; }

function repsFor(ex, sessionsAtThisWeight, rand) {
  const top = ex.repMax, bottom = ex.repMin;
  const span = Math.max(1, top - bottom);
  // A new weight costs reps; owning it takes about two sessions.
  const newness = Math.max(0, Math.round(span * 0.5) - sessionsAtThisWeight * Math.ceil(span / 2));
  // The day itself. Most days are fine; roughly one in three is short by a rep or two.
  const roll = rand();
  const badDay = roll < 0.34 ? (roll < 0.12 ? 2 : 1) : 0;
  const out = [];
  for (let i = 0; i < ex.sets; i++) {
    const fatigue = i > 0 && (newness > 0 || badDay > 0) ? 1 : 0;
    const reps = top - newness - badDay - fatigue;
    out.push({ reps: Math.max(bottom - 2, Math.min(top, reps)) });
  }
  return out;
}

// ---- the calendar ------------------------------------------------------------------
// The Program runs Mon / Tue / Thu / Fri. Today is Wed 19 Aug 2026, so the last Workout
// was Upper A on Tue 18 Aug. 16 weeks back, with two holes the screens have to survive:
// week 7 missed entirely (the gap in the streak grid) and week 12 cut to two days.
const LAST_MONDAY = new Date(Date.UTC(2026, 7, 17));
const WEEKS = 16;
const MISSED_WEEK_INDEX = 6;          // counted from the oldest week
const SHORT_WEEK_INDEX = 11;          // only Upper A and Lower A that week
const ONE_OFF_WEEK = 13;              // a lighter bench away from the home gym
const SKIP_WEEK = 14;                 // one Exercise skipped that day

const MONTH = ['JAN','FEB','MAR','APR','MAY','JUN','JUL','AUG','SEP','OCT','NOV','DEC'];
const fmt = d => `${d.getUTCDate()} ${MONTH[d.getUTCMonth()]}`;
const iso = d => d.toISOString().slice(0, 10);

const mondays = [];
for (let i = WEEKS - 1; i >= 0; i--) {
  const d = new Date(LAST_MONDAY);
  d.setUTCDate(d.getUTCDate() - i * 7);
  mondays.push(d);
}

// The sessions actually performed, oldest first: one entry per Workout Day per week.
const sessions = [];
mondays.forEach((mon, wk) => {
  if (wk === MISSED_WEEK_INDEX) return;
  const dayIdx = wk === SHORT_WEEK_INDEX ? [0, 1] : [0, 1, 2, 3];
  for (const di of dayIdx) {
    // The last week stops after Upper A (Tue 18 Aug): today is Wednesday.
    if (wk === WEEKS - 1 && di > 1) continue;
    const d = new Date(mon);
    d.setUTCDate(d.getUTCDate() + DAY_OFFSET[di]);
    sessions.push({ date: d, week: wk, day: di });
  }
});
sessions.sort((a, b) => a.date - b.date);

// ---- run the program forward -------------------------------------------------------
const state = {};
EXERCISES.forEach((ex, i) => {
  state[ex.key] = { weight: ex.start, atThisWeight: 0, microload: ex.key === 'pull' ? 0 : null, rand: rng(9001 + i * 137) };
});

const workouts = [];

sessions.forEach(({ date, week: idx, day }) => {
  const workout = { date: iso(date), label: fmt(date), day: DAYS[day], dayIndex: day, exercises: [] };

  for (const ex of EXERCISES.filter(e => e.day === day)) {
    const s = state[ex.key];

    if (idx === SKIP_WEEK && ex.key === 'chin') {
      workout.exercises.push({ key: ex.key, name: ex.name, state: 'skipped', sets: [] });
      continue;                                        // a Skipped Exercise logs no Sets
    }

    // A One-off Weight: performed lighter for one Workout, never becomes the Working Weight.
    const oneOff = (idx === ONE_OFF_WEEK && ex.key === 'smith') ? round(s.weight - 7.5) : null;
    const performed = oneOff != null ? oneOff : s.weight;

    const sets = repsFor(ex, s.atThisWeight, s.rand).map(x => ({
      reps: x.reps, weight: performed, unit: ex.unit,
      microload: ex.key === 'pull' ? s.microload : null,
      oneOff: oneOff != null
    }));

    const up = progresses(ex, sets, oneOff);
    const from = { weight: s.weight, microload: s.microload };

    workout.exercises.push({
      key: ex.key, name: ex.name, state: 'completed', equipment: ex.equipment, unit: ex.unit,
      sets, oneOff: oneOff != null, oneOffWeight: oneOff,
      weight: s.weight, microload: s.microload,
      progressed: up, repMin: ex.repMin, repMax: ex.repMax, planned: ex.sets, mode: ex.mode
    });

    if (up) {
      if (ex.mode === 'microloading' && ex.unit !== ex.microplateUnit) {
        // Mixed units: the Microload moves, in the Plate Inventory's unit, and never converts.
        s.microload = round(s.microload + ex.microplate);
      } else if (ex.mode === 'microloading') {
        // Same unit: Microloading moves the Working Weight like any other progression.
        // A bar takes a pair, so the weight moves by twice the Microplate; every other
        // Equipment Type takes one plate and moves by exactly the Microplate.
        const perBar = ['barbell', 'smith', 'plate'].includes(ex.equipment) ? 2 : 1;
        s.weight = round(s.weight + ex.microplate * perBar);
      } else {
        s.weight = round(s.weight + ex.increment);
      }
      s.atThisWeight = 0;
    } else if (oneOff == null) {
      s.atThisWeight++;
    }
    workout.exercises.at(-1).to = { weight: s.weight, microload: s.microload };
    workout.exercises.at(-1).from = from;
  }

  workouts.push(workout);
});

// ---- the streak, as decided: a week counts as soon as it holds one Workout ----------
const counted = new Set(sessions.map(s => s.week));
const weeks = mondays.map((d, i) => ({
  label: fmt(d), on: counted.has(i), count: sessions.filter(s => s.week === i).length
}));
let run = 0;
for (let i = weeks.length - 1; i >= 0; i--) { if (weeks[i].on) run++; else break; }

const out = {
  program: PROGRAM,
  days: DAYS,
  current: Object.fromEntries(EXERCISES.map(e => [e.key, { weight: state[e.key].weight, microload: state[e.key].microload }])),
  exercises: EXERCISES,
  workouts,
  weeks,
  streak: run
};

writeFileSync(new URL('./fixture.json', import.meta.url), JSON.stringify(out, null, 2));

// ---- surface the state, so the numbers on the artboards can be checked --------------
console.log(`${workouts.length} Workouts over ${weeks.length} weeks, streak ${run}`);
console.log(`weeks: ${weeks.map(w => w.count).join(' ')}\n`);
for (const ex of EXERCISES) {
  const line = workouts.filter(w => w.dayIndex === ex.day).map(w => {
    const e = w.exercises.find(x => x.key === ex.key);
    if (e.state === 'skipped') return 'SKIP';
    const reps = e.sets.map(s => s.reps).join(',');
    const w2 = e.oneOff ? `(${e.oneOffWeight})` : e.weight + (e.microload ? `+${e.microload}` : '');
    return `${w2}[${reps}]${e.progressed ? '^' : ' '}`;
  }).join(' ');
  console.log(ex.name.padEnd(30), line);
}
