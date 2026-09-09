/// What hangs on the pin. Lbs ladders never borrow bar plates, so the two paths cannot
/// share a `[Weight]`.
public enum PinHanging: Sendable, Hashable {
    case addOns([Weight])
    case rackPlates([Weight])

    public var iron: [Weight] {
        switch self {
        case .addOns(let weights), .rackPlates(let weights): weights
        }
    }
}

/// Lbs closest and kg leftover. `Rules.breakdown` delegates; the shipping signature
/// does not grow.
enum StackSolve {

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
            return closestLbs(
                target: target,
                ladder: ladder,
                addOns: addOns,
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

    /// Neighboring pins × add-on subsets. Convert the target into the ladder unit once,
    /// then search in that unit. Closest in mass; tie down by smaller loaded mass, then
    /// fewer sliders (195 empty beats 190+5), then lower pin label.
    private static func closestLbs(
        target: Weight,
        ladder: StackLadder,
        addOns: [Weight],
        microload: Weight?,
        microloadPlates: [Weight]
    ) -> StackLoad {
        let converted = target.converted(to: ladder.unit)
        var best: (pin: StackLadder.Pin, addOns: [Weight], loaded: Weight, distance: Int)?
        for pin in neighboringPins(on: ladder, around: converted) {
            for subset in addOnSubsets(addOns) {
                let extra = subset.reduce(0) { $0 + $1.hundredths }
                let loaded = Weight(
                    hundredths: pin.label.hundredths + extra, unit: ladder.unit)
                let distance = abs(loaded.hundredths - converted.hundredths)
                let candidate = (pin, subset, loaded, distance)
                if let current = best {
                    let better =
                        distance < current.distance
                        || (distance == current.distance
                            && (loaded.hundredths < current.loaded.hundredths
                                || (loaded.hundredths == current.loaded.hundredths
                                    && (subset.count < current.addOns.count
                                        || (subset.count == current.addOns.count
                                            && pin.label.hundredths < current.pin.label.hundredths)))))
                    if better { best = candidate }
                } else {
                    best = candidate
                }
            }
        }
        let chosen = best ?? (
            pin: StackLadder.Pin(plate: 1, label: ladder.first),
            addOns: [Weight](),
            loaded: ladder.first,
            distance: 0)
        let loadedTotal = chosen.loaded.converted(to: target.unit)
        return StackLoad(
            blocks: chosen.pin.plate,
            stackStep: ladder.step,
            pinWeight: chosen.pin.label,
            hanging: .addOns(chosen.addOns),
            isExact: loadedTotal == target,
            microload: microload,
            microloadPlates: microloadPlates,
            workingUnit: target.unit,
            loadedTotal: loadedTotal,
            difference: loadedTotal - target)
    }

    /// Pin at or under, leftover as rack plates when the rack shares the ladder unit.
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
        return StackLoad(
            blocks: pin?.plate ?? 0,
            stackStep: step,
            pinWeight: pinWeight,
            hanging: .rackPlates(fill.plates),
            isExact: loadedTotal == target,
            microload: microload,
            microloadPlates: microloadPlates,
            workingUnit: target.unit,
            loadedTotal: loadedTotal,
            difference: loadedTotal - target)
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

    /// Power set. Each subset keeps `sizes` order, biggest first.
    private static func addOnSubsets(_ sizes: [Weight]) -> [[Weight]] {
        var subsets: [[Weight]] = [[]]
        for size in sizes {
            subsets.append(contentsOf: subsets.map { $0 + [size] })
        }
        return subsets
    }
}
