// PROTOTYPE — throwaway. Checks the roll-up rule settled in ticket 16 against real cases.
// The rule must hold two invariants at every progression:
//   1. after a progression the Microload is LESS than one Stack Step
//   2. the total weight NEVER goes down
// Run: node check-rollup.mjs

const LBS_PER_KG = 2.2046226218;
const round = n => Math.round(n * 1e6) / 1e6;
const toKg  = (v, u) => (u === 'kg' ? v : v / LBS_PER_KG);

// Every value the Plate Inventory can build for a hanging load, smallest first.
// Microloading mode may use the whole Inventory (SPEC §5.3), microplates included.
function buildable(inv) {
  const sizes = [...inv.plates, ...inv.microplates].sort((a, b) => a - b);
  const step = sizes[0];
  const out = [0];
  for (let v = step; v <= 30; v = round(v + step)) out.push(v);
  return out;
}
const ceilBuildable = (v, inv) => buildable(inv).find(b => b >= v - 1e-9) ?? v;

// The rule.
function progress(ex, inv) {
  let { weight, microload } = ex;
  microload = round(microload + ex.microplate);        // one Microplate, as always

  // Internal only. SPEC §4.2 already lets Fitty do the mixed-unit arithmetic;
  // what it forbids is SHOWING the converted number, and nothing here is shown.
  const stepInInvUnit = toKg(ex.stackStep, ex.unit) * (inv.unit === 'kg' ? 1 : LBS_PER_KG);

  while (microload >= stepInInvUnit - 1e-9) {
    weight = round(weight + ex.stackStep);             // the pin, in the Exercise's unit
    // Round the remainder UP, so the total can never dip below where it stood.
    microload = ceilBuildable(round(microload - stepInInvUnit), inv);
  }
  return { weight, microload, stepInInvUnit };
}

const totalKg = (s, exUnit, invUnit) => toKg(s.weight, exUnit) + toKg(s.microload, invUnit);

const CASES = [
  { name: 'lbs stack, kg rack, 0.25 microplate',
    ex: { weight: 90, microload: 0, unit: 'lbs', stackStep: 10, microplate: 0.25 },
    inv: { unit: 'kg', plates: [1.25, 2.5, 5, 10, 20], microplates: [0.25, 0.5, 0.75, 1] } },
  { name: 'lbs stack, kg rack, 1 microplate (the case that broke)',
    ex: { weight: 90, microload: 0, unit: 'lbs', stackStep: 10, microplate: 1 },
    inv: { unit: 'kg', plates: [1.25, 2.5, 5, 10, 20], microplates: [1] } },
  { name: 'kg stack, lbs rack, 2.5 lbs microplate',
    ex: { weight: 50, microload: 0, unit: 'kg', stackStep: 5, microplate: 2.5 },
    inv: { unit: 'lbs', plates: [2.5, 5, 10, 25, 45], microplates: [0.5, 1, 1.25, 2.5] } },
  { name: 'tiny stack step, big microplate (every progression rolls)',
    ex: { weight: 40, microload: 0, unit: 'lbs', stackStep: 2.5, microplate: 1 },
    inv: { unit: 'kg', plates: [1.25, 2.5, 5, 10, 20], microplates: [1] } }
];

let failures = 0;
for (const c of CASES) {
  let s = { ...c.ex };
  let prev = totalKg(s, c.ex.unit, c.inv.unit);
  let rolls = 0, maxMicro = 0;
  const trace = [];
  for (let i = 0; i < 40; i++) {
    const before = s.weight;
    s = { ...s, ...progress({ ...c.ex, ...s }, c.inv) };
    const now = totalKg(s, c.ex.unit, c.inv.unit);
    if (s.weight !== before) rolls++;
    maxMicro = Math.max(maxMicro, s.microload);

    if (now < prev - 1e-9) { console.log(`  FAIL down: ${prev} -> ${now}`); failures++; }
    if (s.microload >= s.stepInInvUnit - 1e-9) { console.log(`  FAIL micro >= step`); failures++; }
    if (i < 3 || s.weight !== before) trace.push(`${s.weight} ${c.ex.unit}+${s.microload}`);
    prev = now;
  }
  console.log(`${c.name}\n  40 progressions, ${rolls} pin steps, biggest microload ${maxMicro}` +
              ` (one step = ${round(s.stepInInvUnit)} ${c.inv.unit})\n  ${trace.slice(0, 7).join('  ')}`);
}
console.log(failures ? `\n${failures} FAILURES` : '\nboth invariants hold in every case');
