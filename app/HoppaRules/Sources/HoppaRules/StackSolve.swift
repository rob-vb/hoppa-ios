/// What hangs on the pin. An lbs ladder may also take leftover rack plates in the
/// working unit after the sliders, so the two kinds stay distinct inside one case.
public enum PinHanging: Sendable, Hashable {
    case addOns([Weight], leftover: [Weight])
    case rackPlates([Weight])

    public var iron: [Weight] {
        switch self {
        case .addOns(let addOns, let leftover): addOns + leftover
        case .rackPlates(let plates): plates
        }
    }
}

enum StackSolve {

    private struct Recipe {
        var pin: StackLadder.Pin
        var addOns: [Weight]
        var leftover: [Weight]
        var loadedTotal: Weight
        var spokenPin: Weight
    }

    static func load(
        target: Weight,
        ladder: StackLadder?,
        addOns: [Weight],
        rack: PlateInventory,
        mode: ProgressionMode,
        microload: Weight?,
        microloadPlates: [Weight]
    ) -> StackLoad {
        guard let ladder else {
            return leftover(
                target: target,
                step: .zero(target.unit),
                pin: nil,
                ladderUnit: target.unit,
                rack: rack,
                mode: mode,
                microload: microload,
                microloadPlates: microloadPlates)
        }
        if ladder.unit == .lbs {
            return searchLbs(
                target: target,
                ladder: ladder,
                addOns: addOns,
                rack: rack,
                mode: mode,
                microload: microload,
                microloadPlates: microloadPlates)
        }
        return leftover(
            target: target,
            step: ladder.step,
            pin: ladder.pin(atOrUnder: target.converted(to: ladder.unit)),
            ladderUnit: ladder.unit,
            rack: rack,
            mode: mode,
            microload: microload,
            microloadPlates: microloadPlates)
    }

    /// Neighboring pins × add-on subsets, each scored in spoken working-unit
    /// mass after leftover plates. Tenths recipes match the printed column
    /// (`4.5 kg` on 10 lbs, `6.8 kg` on 15 lbs) and may hang leftover from
    /// that column. Ones recipes exist only when something hangs, so `79 kg
    /// + 1 + 1` still adds and a bare 10 lb plate is never a 5 kg pin.
    private static func searchLbs(
        target: Weight,
        ladder: StackLadder,
        addOns: [Weight],
        rack: PlateInventory,
        mode: ProgressionMode,
        microload: Weight?,
        microloadPlates: [Weight]
    ) -> StackLoad {
        let converted = target.converted(to: ladder.unit)
        let hangLeftover = target.unit != ladder.unit && rack.unit == target.unit
        let sizes = rack.plates(for: mode)
        var best: Recipe?
        for pin in neighboringPins(on: ladder, around: converted) {
            for subset in addOnSubsets(addOns) {
                if hangLeftover {
                    // Tenths only on an exact printed column. Misses keep ones
                    // so 88.8 kg stays `pin at 86 kg · 2.5 kg`, not 195 lbs.
                    if let tenths = hangRecipe(
                        pin: pin, addOns: subset, pinColumn: false,
                        target: target, sizes: sizes
                    ), tenths.loadedTotal == target,
                       better(tenths, than: best, target: target) {
                        best = tenths
                    }
                    if let ones = hangRecipe(
                        pin: pin, addOns: subset, pinColumn: true,
                        target: target, sizes: sizes
                    ), better(ones, than: best, target: target) {
                        best = ones
                    }
                } else {
                    let extra = subset.reduce(0) { $0 + $1.hundredths }
                    let iron = Weight(
                        hundredths: pin.label.hundredths + extra, unit: ladder.unit)
                    let loadedTotal = target.unit == ladder.unit
                        ? iron
                        : iron.converted(to: target.unit)
                    let recipe = Recipe(
                        pin: pin, addOns: subset, leftover: [],
                        loadedTotal: loadedTotal,
                        spokenPin: target.unit == ladder.unit
                            ? pin.label
                            : spokenMass(pin.label, in: target.unit, pinColumn: true))
                    if better(recipe, than: best, target: target) { best = recipe }
                }
            }
        }
        let firstPin = StackLadder.Pin(plate: 1, label: ladder.first)
        let fallbackTotal = target.unit == ladder.unit
            ? ladder.first
            : spokenMass(ladder.first, in: target.unit, pinColumn: false)
        let chosen = best ?? Recipe(
            pin: firstPin, addOns: [], leftover: [],
            loadedTotal: fallbackTotal, spokenPin: fallbackTotal)
        return StackLoad(
            blocks: chosen.pin.plate,
            stackStep: ladder.step,
            pinWeight: chosen.pin.label,
            spokenPinWeight: chosen.spokenPin,
            hanging: .addOns(chosen.addOns, leftover: chosen.leftover),
            isExact: chosen.loadedTotal == target,
            microload: microload,
            microloadPlates: microloadPlates,
            workingUnit: target.unit,
            loadedTotal: chosen.loadedTotal,
            difference: chosen.loadedTotal - target)
    }

    /// Leftover fill from one pin column. Ones recipes with nothing hanging
    /// are dropped: that column is a rounding, not a plate the gym printed.
    private static func hangRecipe(
        pin: StackLadder.Pin,
        addOns: [Weight],
        pinColumn: Bool,
        target: Weight,
        sizes: [Weight]
    ) -> Recipe? {
        let spokenPin = spokenMass(pin.label, in: target.unit, pinColumn: pinColumn)
        let sliders = addOns.reduce(0) {
            $0 + spokenMass($1, in: target.unit, pinColumn: false).hundredths
        }
        let spoken = spokenPin.hundredths + sliders
        let leftoverPlates: [Weight]
        let gap = target.hundredths - spoken
        if gap > 0 {
            let need = Weight(hundredths: gap, unit: target.unit)
            leftoverPlates = exactCover(need, sizes: sizes)
                ?? Rules.greedy(need, sizes: sizes).plates
        } else {
            leftoverPlates = []
        }
        if pinColumn, addOns.isEmpty, leftoverPlates.isEmpty { return nil }
        let hung = leftoverPlates.reduce(0) { $0 + $1.hundredths }
        return Recipe(
            pin: pin, addOns: addOns, leftover: leftoverPlates,
            loadedTotal: Weight(hundredths: spoken + hung, unit: target.unit),
            spokenPin: spokenPin)
    }

    private static func better(_ recipe: Recipe, than current: Recipe?, target: Weight) -> Bool {
        guard let current else { return true }
        let exact = recipe.loadedTotal == target
        let currentExact = current.loadedTotal == target
        if exact != currentExact { return exact }
        let distance = abs(recipe.loadedTotal.hundredths - target.hundredths)
        let currentDistance = abs(current.loadedTotal.hundredths - target.hundredths)
        if distance != currentDistance { return distance < currentDistance }
        if recipe.addOns.count != current.addOns.count {
            return recipe.addOns.count < current.addOns.count
        }
        if recipe.leftover.count != current.leftover.count {
            return recipe.leftover.count < current.leftover.count
        }
        return recipe.pin.label.hundredths < current.pin.label.hundredths
    }

    private static func leftover(
        target: Weight,
        step: Weight,
        pin: StackLadder.Pin?,
        ladderUnit: WeightUnit,
        rack: PlateInventory,
        mode: ProgressionMode,
        microload: Weight?,
        microloadPlates: [Weight]
    ) -> StackLoad {
        let converted = target.converted(to: ladderUnit)
        let pinWeight = pin?.label ?? .zero(ladderUnit)
        let leftoverMass = converted - pinWeight
        let fill = ladderUnit == rack.unit
            ? Rules.greedy(leftoverMass, sizes: rack.plates(for: mode))
            : (plates: [Weight](), remainder: leftoverMass)
        let extra = fill.plates.reduce(0) { $0 + $1.hundredths }
        let iron = Weight(hundredths: pinWeight.hundredths + extra, unit: ladderUnit)
        let loadedTotal = iron.converted(to: target.unit)
        let spokenPin = pinWeight.unit == target.unit
            ? pinWeight
            : spokenMass(pinWeight, in: target.unit, pinColumn: true)
        return StackLoad(
            blocks: pin?.plate ?? 0,
            stackStep: step,
            pinWeight: pinWeight,
            spokenPinWeight: spokenPin,
            hanging: .rackPlates(fill.plates),
            isExact: loadedTotal == target,
            microload: microload,
            microloadPlates: microloadPlates,
            workingUnit: target.unit,
            loadedTotal: loadedTotal,
            difference: loadedTotal - target)
    }

    private static func exactCover(_ need: Weight, sizes: [Weight]) -> [Weight]? {
        let positive = sizes.filter { $0.hundredths > 0 }
        guard need.hundredths > 0 else { return [] }
        var hits: [Int: [Weight]] = [:]
        var misses: Set<Int> = []
        func cover(_ remaining: Int) -> [Weight]? {
            if remaining == 0 { return [] }
            if remaining < 0 { return nil }
            if misses.contains(remaining) { return nil }
            if let hit = hits[remaining] { return hit }
            var found: [Weight]?
            for size in positive where size.hundredths <= remaining {
                if let rest = cover(remaining - size.hundredths) {
                    let combo = [size] + rest
                    if found == nil || finer(combo, than: found!) {
                        found = combo
                    }
                }
            }
            if let found {
                hits[remaining] = found
            } else {
                misses.insert(remaining)
            }
            return found
        }
        return cover(need.hundredths)
    }

    /// Fewest plates, then finer iron. 1 kg + 1 kg beats 1.25 kg + 0.75 kg at 2 kg.
    private static func finer(_ a: [Weight], than b: [Weight]) -> Bool {
        if a.count != b.count { return a.count < b.count }
        let left = a.map(\.hundredths).sorted(by: >)
        let right = b.map(\.hundredths).sorted(by: >)
        return left.lexicographicallyPrecedes(right)
    }

    private static func spokenMass(
        _ weight: Weight, in unit: WeightUnit, pinColumn: Bool
    ) -> Weight {
        if weight.unit == unit { return weight }
        let sticker = pinColumn
            ? Sticker.ones(of: weight, readIn: unit)
            : Sticker(of: weight, readIn: unit)
        return sticker?.asWeight ?? weight.converted(to: unit)
    }

    private static func neighboringPins(
        on ladder: StackLadder, around target: Weight
    ) -> [StackLadder.Pin] {
        if let at = ladder.pin(atOrUnder: target) {
            var pins = [at, StackLadder.Pin(plate: at.plate + 1, label: at.label + ladder.step)]
            if at.plate > 1 {
                pins.append(StackLadder.Pin(plate: at.plate - 1, label: at.label - ladder.step))
            }
            return pins
        }
        return [StackLadder.Pin(plate: 1, label: ladder.first)]
    }

    private static func addOnSubsets(_ sizes: [Weight]) -> [[Weight]] {
        var subsets: [[Weight]] = [[]]
        for size in sizes {
            subsets.append(contentsOf: subsets.map { $0 + [size] })
        }
        return subsets
    }
}
