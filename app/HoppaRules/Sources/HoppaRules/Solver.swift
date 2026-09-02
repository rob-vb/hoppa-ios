/// What the user must load, per Equipment Type (`SPEC.md` §5.5).
public enum PlateBreakdown: Sendable, Hashable {
    /// Barbell and Machine (Plates) draw the same loaded bar.
    /// The Base Weight is the only difference, and it lives in text.
    case bar(BarLoad)
    case stack(StackLoad)
    case dumbbell(each: Weight)
    case bodyweight(added: Weight, plates: [Weight])
}

public struct BarLoad: Sendable, Hashable {
    /// The bar or the empty carriage. A Barbell prints none.
    public var baseWeight: Weight
    /// Whether the Base Weight is worth printing: a Barbell's bar is standard.
    public var printsBaseWeight: Bool
    /// What actually goes on each side.
    public var perSide: Weight
    /// Per side, biggest first.
    public var plates: [Weight]
    /// False when the rack cannot build the Working Weight, and `≈ CLOSEST` appears.
    public var isExact: Bool
    /// `baseWeight + 2 × perSide`. What the user really lifts.
    public var loadedTotal: Weight
    /// `loadedTotal` minus the Working Weight. Positive is over, negative is under.
    public var difference: Weight
}

public struct StackLoad: Sendable, Hashable {
    /// How many pin steps are under the pin.
    public var blocks: Int
    public var stackStep: Weight
    /// `blocks × stackStep`. The pin takes the largest Stack Step at or under the
    /// Working Weight (`SPEC.md` §5.3).
    public var pinWeight: Weight
    /// The part of the Working Weight the pin cannot reach, as plates. Same unit only.
    public var pinRemainder: [Weight]
    public var isExact: Bool
    /// The Microload, on a mixed-unit pin only. Never converted, never totalled.
    public var microload: Weight?
    /// The Microload drawn as plates: identical plates are never stacked, so 1.25 kg of
    /// Microload is one 1.25 kg plate and not five 0.25s (`SPEC.md` §5.3).
    public var microloadPlates: [Weight]
}

extension Rules {

    /// The standard bar. A Barbell prints no Base Weight; the bar is standard (§2.6).
    public static func standardBarWeight(_ unit: WeightUnit) -> Weight {
        switch unit {
        case .kg: .kg(hundredths: 2000)
        case .lbs: .lbs(hundredths: 4500)
        }
    }

    /// Greedy, from the biggest plate down (`SPEC.md` §5.3). The rack holds no count of
    /// pairs, so every size is unlimited.
    public static func greedy(_ target: Weight, sizes: [Weight]) -> (plates: [Weight], remainder: Weight) {
        var remaining = target
        var out: [Weight] = []
        guard remaining.hundredths > 0 else { return ([], remaining) }
        for size in sizes where size.hundredths > 0 {
            while remaining.hundredths >= size.hundredths {
                out.append(size)
                remaining = remaining - size
            }
        }
        return (out, remaining)
    }

    /// The closest load the rack can build, up or down. **On a tie, Hoppa rounds down**
    /// (`SPEC.md` §5.4). Every buildable load is a multiple of the smallest plate,
    /// because counts are unlimited.
    static func closestBuildable(_ target: Weight, step: Weight) -> Weight {
        guard step.hundredths > 0 else { return target }
        if target.hundredths <= 0 { return Weight(hundredths: 0, unit: target.unit) }
        let stepsDown = target.hundredths / step.hundredths
        let down = Weight(hundredths: stepsDown * step.hundredths, unit: target.unit)
        let up = Weight(hundredths: (stepsDown + 1) * step.hundredths, unit: target.unit)
        let distanceDown = target.hundredths - down.hundredths
        let distanceUp = up.hundredths - target.hundredths
        return distanceUp < distanceDown ? up : down
    }

    /// Solves the Plate Breakdown for one Exercise at the weight it is being performed at.
    ///
    /// The big number is **always the Working Weight Hoppa tracks**: it never changes to
    /// fit the plate rack (`SPEC.md` §5.4). Only this drawing deals with the gap.
    ///
    /// `nil` when there is no weight to draw: the Working Weight is unset and no One-off
    /// stands in for it (`SPEC.md` §2.8). The solve itself takes a concrete `Weight`; the
    /// unwrapping happens here, once, so no rule below has to think about it.
    public static func breakdown(
        for exercise: ResolvedExercise,
        performedAt oneOffWeight: Weight? = nil,
        inventory: PlateInventory
    ) -> PlateBreakdown? {
        guard let performed = oneOffWeight ?? exercise.workingWeight else { return nil }
        return breakdown(for: exercise, at: performed, inventory: inventory)
    }

    /// The solve, at a weight that is known.
    public static func breakdown(
        for exercise: ResolvedExercise,
        at weight: Weight,
        inventory: PlateInventory
    ) -> PlateBreakdown {
        let target = weight.relabelled(exercise.unit)
        let sizes = inventory.plates(for: exercise.mode)

        if exercise.equipment.isBarLoaded {
            let base = exercise.baseWeight ?? standardBarWeight(exercise.unit)
            let added = target - base
            if added.hundredths <= 0 {
                return .bar(BarLoad(
                    baseWeight: base,
                    printsBaseWeight: exercise.equipment.takesBaseWeight,
                    perSide: .zero(exercise.unit),
                    plates: [],
                    isExact: added.hundredths == 0,
                    loadedTotal: base,
                    difference: base - target))
            }

            // Solved on the total added weight with the plate sizes doubled, so a
            // per-side target that is not a whole number of hundredths (61.25 kg on a
            // 20 kg bar is 20.625 per side) never has to be represented.
            let doubled = sizes.map { $0.scaled(by: 2) }
            let exactSolve = greedy(added, sizes: doubled)
            if exactSolve.remainder.hundredths == 0 {
                let perSide = Weight(hundredths: added.hundredths / 2, unit: exercise.unit)
                return .bar(BarLoad(
                    baseWeight: base,
                    printsBaseWeight: exercise.equipment.takesBaseWeight,
                    perSide: perSide,
                    plates: exactSolve.plates.map { Weight(hundredths: $0.hundredths / 2, unit: exercise.unit) },
                    isExact: true,
                    loadedTotal: target,
                    difference: .zero(exercise.unit)))
            }

            guard let smallest = sizes.last else {
                return .bar(BarLoad(
                    baseWeight: base,
                    printsBaseWeight: exercise.equipment.takesBaseWeight,
                    perSide: .zero(exercise.unit),
                    plates: [],
                    isExact: false,
                    loadedTotal: base,
                    difference: base - target))
            }
            let buildable = closestBuildable(added, step: smallest.scaled(by: 2))
            let solve = greedy(buildable, sizes: doubled)
            let perSide = Weight(hundredths: buildable.hundredths / 2, unit: exercise.unit)
            let loaded = base + buildable
            return .bar(BarLoad(
                baseWeight: base,
                printsBaseWeight: exercise.equipment.takesBaseWeight,
                perSide: perSide,
                plates: solve.plates.map { Weight(hundredths: $0.hundredths / 2, unit: exercise.unit) },
                isExact: false,
                loadedTotal: loaded,
                difference: loaded - target))
        }

        switch exercise.equipment {
        case .machineStack:
            let step = exercise.stackStep ?? .zero(exercise.unit)
            let blocks = step.hundredths > 0 ? max(0, target.hundredths / step.hundredths) : 0
            let pinWeight = Weight(hundredths: blocks * step.hundredths, unit: exercise.unit)
            let leftover = target - pinWeight
            // A pin takes single plates, not a pair. Only a same-unit rack can fill it.
            let fill = exercise.unit == inventory.unit
                ? greedy(leftover, sizes: sizes)
                : (plates: [Weight](), remainder: leftover)
            let microloadPlates = exercise.microload.map { greedy($0, sizes: inventory.plates(for: .microloading)).plates } ?? []
            return .stack(StackLoad(
                blocks: blocks,
                stackStep: step,
                pinWeight: pinWeight,
                pinRemainder: fill.plates,
                isExact: fill.remainder.hundredths == 0,
                microload: exercise.microload,
                microloadPlates: microloadPlates))

        case .dumbbell:
            return .dumbbell(each: target)

        case .bodyweight:
            return .bodyweight(added: target, plates: greedy(target, sizes: sizes).plates)

        case .barbell, .machinePlates:
            preconditionFailure("handled above")
        }
    }
}
