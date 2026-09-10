import Testing
import HoppaRules

@Suite("StackSolve — lbs search, kg leftover")
struct StackSolveTests {

    @Test("Resolve does not relabel a lbs step onto a kg hero")
    func resolveKeepsTheLadderUnit() {
        let fly = Exercise(
            id: ExerciseID(1), name: "Chest fly machine", equipment: .machineStack,
            ownWeightUnit: .kg,
            plannedSets: 2, repRange: RepRange(6, 8),
            workingWeight: kg("88.8"), increment: kg("5"),
            storedStackStep: lbs("5"))
        let resolved = fly.resolved(mode: .progressiveOverload, inventory: .standard(.kg))
        #expect(resolved.unit == .kg)
        #expect(resolved.stack?.unit == .lbs)
        #expect(resolved.stack?.step == lbs("5"))
        #expect(resolved.stackAddOns == [lbs("5"), lbs("2.5")])
    }

    @Test("88.8 kg on a 5 lb step hangs a 2.5 kg plate on the 190 lb pin")
    func chestFlyCrossUnit() {
        let fly = Exercise(
            id: ExerciseID(1), name: "Chest fly machine", equipment: .machineStack,
            ownWeightUnit: .kg,
            plannedSets: 2, repRange: RepRange(6, 8),
            workingWeight: kg("88.8"), increment: kg("5"),
            storedStackStep: lbs("5"))
        let inventory = PlateInventory.standard(.kg)
        let resolved = fly.resolved(mode: .progressiveOverload, inventory: inventory)
        guard case .stack(let load) = Rules.breakdown(for: resolved, inventory: inventory)
        else { Issue.record("expected a stack"); return }

        #expect(load.pinWeight == lbs("190"))
        #expect(load.hanging == .addOns([], leftover: [kg("2.5")]))
        #expect(!load.isExact)
        #expect(load.loadedTotal == kg("88.5"))
        #expect(load.difference.hundredths == -30)
        #expect(load.difference.unit == .kg)
        #expect(load.workingUnit == .kg)
        #expect(load.microload == nil)
    }

    @Test("88.8 kg on a 10 lb stack is 86 kg + 2.3 kg + 0.5 kg")
    func chestFlyTenPoundStackHitsTheStickerSum() {
        var inventory = PlateInventory.standard(.kg)
        inventory.setPlate(kg("0.5"), on: true)
        let fly = Exercise(
            id: ExerciseID(1), name: "Chest fly machine", equipment: .machineStack,
            ownWeightUnit: .kg,
            plannedSets: 2, repRange: RepRange(6, 8),
            workingWeight: kg("88.8"), increment: kg("5"),
            microloadingIncrement: kg("0.5"),
            modeOverride: .microloading,
            storedStackStep: lbs("10"))
        let resolved = fly.resolved(mode: .microloading, inventory: inventory)
        guard case .stack(let load) = Rules.breakdown(for: resolved, inventory: inventory)
        else { Issue.record("expected a stack"); return }

        #expect(load.pinWeight == lbs("190"))
        #expect(load.pinRemainder == [lbs("5"), kg("0.5")])
        #expect(load.isExact)
        #expect(load.loadedTotal == kg("88.8"))
        #expect(load.difference == kg("0"))
        #expect(load.workingUnit == .kg)
        #expect(load.microload == nil)
    }

    @Test("87.5 kg on a 5 kg step still hangs a 2.5 kg rack plate")
    func kgLeftoverUnchanged() {
        let fly = Exercise(
            id: ExerciseID(1), name: "Chest fly machine", equipment: .machineStack,
            ownWeightUnit: .kg,
            plannedSets: 2, repRange: RepRange(6, 8),
            workingWeight: kg("87.5"), increment: kg("5"),
            storedStackStep: kg("5"))
        let inventory = PlateInventory.standard(.kg)
        let resolved = fly.resolved(mode: .progressiveOverload, inventory: inventory)
        #expect(resolved.stackAddOns.isEmpty)
        guard case .stack(let load) = Rules.breakdown(for: resolved, inventory: inventory)
        else { Issue.record("expected a stack"); return }

        #expect(load.pinWeight == kg("85"))
        #expect(load.hanging == .rackPlates([kg("2.5")]))
        #expect(load.isExact)
        #expect(load.loadedTotal == kg("87.5"))
    }

    @Test("100 lbs + 1 kg microload stays mixed and is not in loadedTotal")
    func mixedMicroloadUnchanged() {
        var inventory = PlateInventory.standard(.kg)
        inventory.setPlate(kg("1"), on: true)
        let pulldown = Exercise(
            id: ExerciseID(12), name: "Lat pulldown", equipment: .machineStack,
            ownWeightUnit: .lbs,
            plannedSets: 3, repRange: RepRange(10, 12),
            workingWeight: lbs("100"), increment: lbs("10"),
            microloadingIncrement: kg("1"),
            modeOverride: .microloading,
            storedStackStep: lbs("10"),
            microload: kg("1"))
        let resolved = pulldown.resolved(mode: .microloading, inventory: inventory)
        guard case .stack(let load) = Rules.breakdown(for: resolved, inventory: inventory)
        else { Issue.record("expected a stack"); return }

        #expect(load.pinWeight == lbs("100"))
        #expect(load.hanging == .addOns([], leftover: []))
        #expect(load.microload == kg("1"))
        #expect(load.microloadPlates == [kg("1")])
        #expect(load.loadedTotal == lbs("100"))
        #expect(load.isExact)
    }

    @Test("Add-ons off: nearest pin only, no rack leftover on an lbs ladder")
    func addOnsOffNoRackBorrow() {
        var inventory = PlateInventory.standard(.lbs)
        inventory.setAddOn(.twoAndAHalfLbs, on: false)
        inventory.setAddOn(.fiveLbs, on: false)
        let pulldown = Exercise(
            id: ExerciseID(12), name: "Lat pulldown", equipment: .machineStack,
            ownWeightUnit: .lbs,
            plannedSets: 3, repRange: RepRange(10, 12),
            workingWeight: lbs("105"), increment: lbs("10"),
            storedStackStep: lbs("10"))
        let resolved = pulldown.resolved(mode: .progressiveOverload, inventory: inventory)
        #expect(resolved.stackAddOns.isEmpty)
        guard case .stack(let load) = Rules.breakdown(for: resolved, inventory: inventory)
        else { Issue.record("expected a stack"); return }

        #expect(load.pinWeight == lbs("100"))
        #expect(load.hanging == .addOns([], leftover: []))
        #expect(load.pinRemainder.isEmpty)
        #expect(!load.isExact)
        #expect(load.loadedTotal == lbs("100"))
    }

    @Test("81 kg on a 5 lb stack hangs leftover kg, not the 2.5 lb slider")
    func latPulldownEightyOneHitsExact() {
        var inventory = PlateInventory.standard(.kg)
        inventory.setPlate(kg("1"), on: true)
        inventory.setPlate(kg("0.75"), on: true)
        inventory.setPlate(kg("0.5"), on: true)
        inventory.setPlate(kg("0.25"), on: true)
        let pulldown = Exercise(
            id: ExerciseID(12), name: "Lat pulldown", equipment: .machineStack,
            ownWeightUnit: .kg,
            plannedSets: 2, repRange: RepRange(6, 8),
            workingWeight: kg("81"), increment: kg("0.5"),
            microloadingIncrement: kg("0.5"),
            modeOverride: .microloading,
            storedStackStep: lbs("5"))
        let resolved = pulldown.resolved(mode: .microloading, inventory: inventory)
        guard case .stack(let load) = Rules.breakdown(for: resolved, inventory: inventory)
        else { Issue.record("expected a stack"); return }

        #expect(load.pinWeight == lbs("175"))
        guard case .addOns(let addOns, let leftover) = load.hanging else {
            Issue.record("expected add-ons hanging"); return
        }
        #expect(addOns.isEmpty)
        #expect(leftover == [kg("1"), kg("1")])
        #expect(load.isExact)
        #expect(load.loadedTotal == kg("81"))
        #expect(load.difference == kg("0"))
    }

    @Test("6.8 kg is the 15 lb plate, not pin at 2 kg plus hangers")
    func fifteenPoundPinIsThePrintedSixPointEight() {
        var inventory = PlateInventory.standard(.kg)
        inventory.setPlate(kg("1"), on: true)
        inventory.setPlate(kg("0.75"), on: true)
        inventory.setPlate(kg("0.5"), on: true)
        inventory.setPlate(kg("0.25"), on: true)
        let press = Exercise(
            id: ExerciseID(6), name: "Chest press machine", equipment: .machineStack,
            ownWeightUnit: .kg,
            plannedSets: 2, repRange: RepRange(6, 8),
            workingWeight: kg("6.8"), increment: kg("0.5"),
            microloadingIncrement: kg("0.5"),
            modeOverride: .microloading,
            storedStackStep: lbs("5"))
        let resolved = press.resolved(mode: .microloading, inventory: inventory)
        guard case .stack(let load) = Rules.breakdown(for: resolved, inventory: inventory)
        else { Issue.record("expected a stack"); return }

        #expect(load.pinWeight == lbs("15"))
        #expect(load.hanging == .addOns([], leftover: []))
        #expect(load.isExact)
        #expect(load.loadedTotal == kg("6.8"))
        #expect(load.difference == kg("0"))
    }

    @Test("5 kg is 10 lbs plus 0.5 kg, not a 5 kg pin")
    func tenPoundPinPrintsFourPointFive() {
        var inventory = PlateInventory.standard(.kg)
        inventory.setPlate(kg("1"), on: true)
        inventory.setPlate(kg("0.5"), on: true)
        let press = Exercise(
            id: ExerciseID(6), name: "Chest press machine", equipment: .machineStack,
            ownWeightUnit: .kg,
            plannedSets: 2, repRange: RepRange(6, 8),
            workingWeight: kg("5"), increment: kg("0.5"),
            microloadingIncrement: kg("0.5"),
            modeOverride: .microloading,
            storedStackStep: lbs("5"))
        let resolved = press.resolved(mode: .microloading, inventory: inventory)
        guard case .stack(let load) = Rules.breakdown(for: resolved, inventory: inventory)
        else { Issue.record("expected a stack"); return }

        #expect(load.pinWeight == lbs("10"))
        #expect(load.columnMass == kg("4.5"))
        #expect(load.hanging == .addOns([], leftover: [kg("0.5")]))
        #expect(load.isExact)
        #expect(load.loadedTotal == kg("5"))
        #expect(load.difference == kg("0"))
    }

    @Test("81 kg still hits with two 1 kg plates when 0.75 is off")
    func latPulldownEightyOneSkipsTheTooBigPlate() {
        var inventory = PlateInventory.standard(.kg)
        inventory.setPlate(kg("1"), on: true)
        inventory.setPlate(kg("0.75"), on: false)
        let pulldown = Exercise(
            id: ExerciseID(12), name: "Lat pulldown", equipment: .machineStack,
            ownWeightUnit: .kg,
            plannedSets: 2, repRange: RepRange(6, 8),
            workingWeight: kg("81"), increment: kg("0.5"),
            microloadingIncrement: kg("1"),
            modeOverride: .microloading,
            storedStackStep: lbs("5"))
        let resolved = pulldown.resolved(mode: .microloading, inventory: inventory)
        guard case .stack(let load) = Rules.breakdown(for: resolved, inventory: inventory)
        else { Issue.record("expected a stack"); return }

        #expect(load.pinWeight == lbs("175"))
        #expect(load.hanging == .addOns([], leftover: [kg("1"), kg("1")]))
        #expect(load.isExact)
        #expect(load.loadedTotal == kg("81"))
    }

    @Test("59.5 kg on a 5 lb stack is 56.7 kg plus 2.5 kg, not a 57 kg pin")
    func fiftyNineFiveIsNotAFiftySevenPin() {
        let fly = Exercise(
            id: ExerciseID(1), name: "Chest fly machine", equipment: .machineStack,
            ownWeightUnit: .kg,
            plannedSets: 2, repRange: RepRange(6, 8),
            workingWeight: kg("59.5"), increment: kg("5"),
            storedStackStep: lbs("5"))
        let inventory = PlateInventory.standard(.kg)
        let resolved = fly.resolved(mode: .progressiveOverload, inventory: inventory)
        guard case .stack(let load) = Rules.breakdown(for: resolved, inventory: inventory)
        else { Issue.record("expected a stack"); return }

        #expect(load.pinWeight == lbs("125"))
        #expect(load.columnMass == kg("56.7"))
        #expect(load.hanging == .addOns([], leftover: [kg("2.5")]))
        #expect(!load.isExact)
        #expect(load.loadedTotal == kg("59.2"))
        #expect(load.difference.hundredths == -30)
        #expect(load.workingUnit == .kg)
    }

    @Test("89.2 kg on a 5 lb step hangs the 2.5 lb slider")
    func chestFlyHangsTwoAndAHalf() {
        let fly = Exercise(
            id: ExerciseID(1), name: "Chest fly machine", equipment: .machineStack,
            ownWeightUnit: .kg,
            plannedSets: 2, repRange: RepRange(6, 8),
            workingWeight: kg("89.2"), increment: kg("5"),
            storedStackStep: lbs("5"))
        let inventory = PlateInventory.standard(.kg)
        let resolved = fly.resolved(mode: .progressiveOverload, inventory: inventory)
        guard case .stack(let load) = Rules.breakdown(for: resolved, inventory: inventory)
        else { Issue.record("expected a stack"); return }

        #expect(load.pinWeight == lbs("195"))
        #expect(load.hanging == .addOns([lbs("2.5")], leftover: []))
        #expect(!load.isExact)
    }

    @Test("66 kg on a 15 lb stack sits on the 66 kg plate")
    func sixtySixIsTheHundredFortyFivePlate() {
        let quad = Exercise(
            id: ExerciseID(3), name: "Leg extension", equipment: .machineStack,
            ownWeightUnit: .kg,
            plannedSets: 2, repRange: RepRange(6, 8),
            workingWeight: kg("66"), increment: kg("5"),
            storedStackStep: lbs("15"),
            storedStackFirstPlate: lbs("10"))
        let inventory = PlateInventory.standard(.kg)
        let resolved = quad.resolved(mode: .progressiveOverload, inventory: inventory)
        guard case .stack(let load) = Rules.breakdown(for: resolved, inventory: inventory)
        else { Issue.record("expected a stack"); return }

        #expect(load.pinWeight == lbs("145"))
        #expect(load.columnMass == kg("66"))
        #expect(load.hanging == .addOns([], leftover: []))
        #expect(load.isExact)
        #expect(load.loadedTotal == kg("66"))
    }

    @Test("59 kg on a 15 lb stack sits on the 59 kg plate")
    func fiftyNineIsTheHundredThirtyPlate() {
        let hip = Exercise(
            id: ExerciseID(4), name: "Hip abduction", equipment: .machineStack,
            ownWeightUnit: .kg,
            plannedSets: 2, repRange: RepRange(6, 8),
            workingWeight: kg("59"), increment: kg("5"),
            storedStackStep: lbs("15"),
            storedStackFirstPlate: lbs("10"))
        let inventory = PlateInventory.standard(.kg)
        let resolved = hip.resolved(mode: .progressiveOverload, inventory: inventory)
        guard case .stack(let load) = Rules.breakdown(for: resolved, inventory: inventory)
        else { Issue.record("expected a stack"); return }

        #expect(load.pinWeight == lbs("130"))
        #expect(load.columnMass == kg("59"))
        #expect(load.hanging == .addOns([], leftover: []))
        #expect(load.isExact)
        #expect(load.loadedTotal == kg("59"))
    }
}
