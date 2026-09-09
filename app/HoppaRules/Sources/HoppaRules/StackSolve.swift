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

    private static func closestLbs(
        target: Weight,
        ladder: StackLadder,
        addOns: [Weight],
        rack: PlateInventory,
        mode: ProgressionMode,
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
        let leftoverPlates: [Weight]
        let loadedTotal: Weight
        if target.unit != ladder.unit, rack.unit == target.unit {
            let spoken =
                spokenMass(chosen.pin.label, in: target.unit, pinColumn: true).hundredths
                + chosen.addOns.reduce(0) {
                    $0 + spokenMass($1, in: target.unit, pinColumn: false).hundredths
                }
            let gap = target.hundredths - spoken
            leftoverPlates = gap > 0
                ? Rules.greedy(
                    Weight(hundredths: gap, unit: target.unit),
                    sizes: rack.plates(for: mode)).plates
                : []
            let hung = leftoverPlates.reduce(0) { $0 + $1.hundredths }
            loadedTotal = Weight(hundredths: spoken + hung, unit: target.unit)
        } else {
            leftoverPlates = []
            loadedTotal = target.unit == ladder.unit
                ? chosen.loaded
                : chosen.loaded.converted(to: target.unit)
        }
        return StackLoad(
            blocks: chosen.pin.plate,
            stackStep: ladder.step,
            pinWeight: chosen.pin.label,
            hanging: .addOns(chosen.addOns, leftover: leftoverPlates),
            isExact: loadedTotal == target,
            microload: microload,
            microloadPlates: microloadPlates,
            workingUnit: target.unit,
            loadedTotal: loadedTotal,
            difference: loadedTotal - target)
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
