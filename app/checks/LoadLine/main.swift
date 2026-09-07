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
    mode: ProgressionMode = .progressiveOverload,
    inventory: PlateInventory = .standard(.kg),
    microload: Weight? = nil
) -> StackLoad {
    let working = Weight(decimalString: weight, unit: unit)!
    let stepWeight = Weight(decimalString: step, unit: unit)!
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

if failures > 0 {
    print("\(failures) failed")
    exit(1)
}
print("all green")
