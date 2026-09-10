// Ticket 0060 — the stack's load line names the plates, not a count of microplates.
//
// `DomainCopy.swift` is the **real file**, compiled in beside this one. The solve is
// `Rules.breakdown`, the shipping call. What this proves is the English the logging
// screen prints for a pin, against the same remainder the drawing hangs.
//
// Run it with `./run.sh`.
import Foundation
import HoppaRules

nonisolated(unsafe) var failures = 0
func check(_ what: String, _ ok: Bool) {
    print((ok ? "ok   " : "FAIL ") + what)
    if !ok { failures += 1 }
}

func kg(_ text: String) -> Weight { Weight(decimalString: text, unit: .kg)! }
func lbs(_ text: String) -> Weight { Weight(decimalString: text, unit: .lbs)! }

func stack(
    _ weight: String, unit: WeightUnit = .kg, step: String,
    stepUnit: WeightUnit? = nil,
    mode: ProgressionMode = .progressiveOverload,
    inventory: PlateInventory = .standard(.kg),
    microload: Weight? = nil
) -> StackLoad {
    let working = Weight(decimalString: weight, unit: unit)!
    let ladderUnit = stepUnit ?? unit
    let stepWeight = Weight(decimalString: step, unit: ladderUnit)!
    let exercise = Exercise(
        id: ExerciseID(1), name: "Chest fly machine", equipment: .machineStack,
        ownWeightUnit: unit,
        plannedSets: 2, repRange: RepRange(6, 8),
        workingWeight: working, increment: stepWeight,
        modeOverride: mode,
        storedStackStep: stepWeight,
        microload: microload)
    let resolved = exercise.resolved(mode: mode, inventory: inventory)
    guard case .stack(let load) = Rules.breakdown(for: resolved, inventory: inventory) else {
        fatalError("expected a stack at \(weight)")
    }
    return load
}

// MARK: - The Chest fly case — Rob's own 87.5

let fly = stack("87.5", step: "5")
check("87.5 kg names the 2.5 kg plate", fly.loadLine == "pin at 85 kg · 2.5 kg")
check("87.5 kg does not say microplate", !fly.loadLine.contains("microplate"))
check("87.5 kg qualifier is the math", fly.qualifierLine == "85 kg + 2.5")
check("the remainder is a 2.5, not a Microplate", fly.pinRemainder == [kg("2.5")])

// MARK: - An exact pin hangs nothing

let exact = stack("85", step: "5")
check("an exact pin is only the pin", exact.loadLine == "pin at 85 kg")
check("an exact pin has no hanging clause", !exact.loadLine.contains("·"))
check("an exact pin's qualifier is the pin", exact.qualifierLine == "85 kg")

// MARK: - Two remainder plates

var coarse = PlateInventory.standard(.kg)
coarse.setPlate(kg("2.5"), on: false)
let two = stack("87.5", step: "5", inventory: coarse)
check("2.5 off splits into two 1.25s", two.loadLine == "pin at 85 kg · 1.25 kg + 1.25 kg")
check("two 1.25s still do not say microplate", !two.loadLine.contains("microplate"))

// MARK: - A real Microplate still names its size

var fine = PlateInventory.standard(.kg)
fine.setPlate(kg("0.5"), on: true)
let micro = stack("85.5", step: "5", mode: .microloading, inventory: fine)
check("a 0.5 kg Microplate prints 0.5 kg", micro.loadLine == "pin at 85 kg · 0.5 kg")
check("even a real Microplate is not counted as one", !micro.loadLine.contains("microplate"))

// MARK: - Mixed units keep the hang-on's own unit

var mixedRack = PlateInventory.standard(.kg)
mixedRack.setPlate(kg("1"), on: true)
let mixed = stack(
    "100", unit: .lbs, step: "10",
    mode: .microloading, inventory: mixedRack, microload: kg("1"))
check("lbs pin + kg plate keeps both units", mixed.loadLine == "pin at 100 lbs · 1 kg")
check("mixed qualifier never totals", mixed.qualifierLine == "100 lbs + 1 kg")
check("mixed does not say microplate either", !mixed.loadLine.contains("microplate"))

// MARK: - Chest fly in kg on a 5 lb stack

let flyLbs = stack("88.8", unit: .kg, step: "5", stepUnit: .lbs)
check("88.8 kg / 5 lbs names the kg column plus leftover", flyLbs.loadLine == "pin at 86 kg · 2.5 kg")
check("88.8 kg hangs a 2.5 kg plate", flyLbs.pinRemainder == [kg("2.5")])
check("88.8 kg is not exact", !flyLbs.isExact)
check("88.8 kg loadedTotal is pin plus leftover", flyLbs.loadedTotal == kg("88.5"))
check("88.8 kg qualifier adds leftover", flyLbs.qualifierLine == "86 kg + 2.5")

// MARK: - An lbs slider in a kg UI speaks kg

let withSlider = stack("89.2", unit: .kg, step: "5", stepUnit: .lbs)
check("89.2 kg hangs 1.1 kg", withSlider.loadLine == "pin at 88 kg · 1.1 kg")
check("89.2 kg hanging is the 2.5 lb slider", withSlider.pinRemainder == [lbs("2.5")])

// MARK: - The Basic Fit chest fly: 10 lb stack, 0.5 kg on the pin

var gym = PlateInventory.standard(.kg)
gym.setPlate(kg("0.5"), on: true)
let flyTen = stack(
    "88.8", unit: .kg, step: "10", stepUnit: .lbs,
    mode: .microloading, inventory: gym)
check(
    "88.8 kg on 10 lbs is pin + slider + micro",
    flyTen.loadLine == "pin at 86 kg · 2.3 kg + 0.5 kg")
check("88.8 kg qualifier adds in kg", flyTen.qualifierLine == "86 kg + 2.3 + 0.5")
check("88.8 kg on 10 lbs is exact", flyTen.isExact)
check("88.8 kg loadedTotal is the sticker sum", flyTen.loadedTotal == kg("88.8"))

// MARK: - 81 kg lat pulldown: leftover kg, not the 2.5 lb slider

var pulldownGym = PlateInventory.standard(.kg)
pulldownGym.setPlate(kg("1"), on: true)
pulldownGym.setPlate(kg("0.75"), on: true)
let pulldown81 = stack(
    "81", unit: .kg, step: "5", stepUnit: .lbs,
    mode: .microloading, inventory: pulldownGym)
check("81 kg is exact", pulldown81.isExact)
check("81 kg hangs two 1 kg plates", pulldown81.loadLine == "pin at 79 kg · 1 kg + 1 kg")
check("81 kg qualifier is the math", pulldown81.qualifierLine == "79 kg + 1 + 1")
check("81 kg loadedTotal is the typed weight", pulldown81.loadedTotal == kg("81"))

// MARK: - 6.8 kg is the 15 lb plate, not 2 kg + hangers

var pressGym = PlateInventory.standard(.kg)
pressGym.setPlate(kg("1"), on: true)
pressGym.setPlate(kg("0.5"), on: true)
let press68 = stack(
    "6.8", unit: .kg, step: "5", stepUnit: .lbs,
    mode: .microloading, inventory: pressGym)
check("6.8 kg is exact", press68.isExact)
check("6.8 kg is only the pin", press68.loadLine == "pin at 6.8 kg")
check("6.8 kg hangs nothing", press68.pinRemainder.isEmpty)
check("6.8 kg qualifier is the pin", press68.qualifierLine == "6.8 kg")
check("6.8 kg loadedTotal is the typed weight", press68.loadedTotal == kg("6.8"))

if failures > 0 {
    print("\(failures) failed")
    exit(1)
}
print("all green")
