import Testing
import HoppaRules

@Suite("StackSolve — lbs closest, kg leftover")
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

    @Test("88.8 kg on a 5 lb step pins at 195 lbs, no slider")
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

        #expect(load.pinWeight == lbs("195"))
        #expect(load.hanging == .addOns([], leftover: []))
        #expect(load.pinRemainder.isEmpty)
        #expect(!load.isExact)
        #expect(load.loadedTotal == kg("88"))
        #expect(load.difference.hundredths == -80)
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
}
