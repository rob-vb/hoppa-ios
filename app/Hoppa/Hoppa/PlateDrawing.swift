import SwiftUI
import HoppaRules

// Ticket 0036 — §7.5's signature, drawn.
//
// **Plain `Shape`s in an `HStack`**, settled at
// [Drawing the loaded bar and the Ignition confetti](0031-drawing-the-bar-and-the-confetti.md):
// the bar *is* a row of rounded rectangles, so `Canvas` would mean computing every
// x-offset by hand to get back the one thing `HStack` already does. The confetti went the
// other way, and ticket 0039 owns it.
//
// **This view decides nothing.** It renders a `PlateBreakdown` that `Rules.breakdown`
// already solved — which plates go on the bar, where the pin sits, and whether the rack
// can build the number at all are rules, and they are green in `HoppaRules`.
//
// §7.1 rule 2 runs through every line below and it is the reason the steel looks the way
// it does: **a plate is always a filled shape, and steel is never filled.** So a plate is
// `.fill` plus §7.3's rim, and the collars, the sleeve stops, the knurled shaft, a stack's
// blocks and a belt clip are all 1 px strokes with nothing inside them. Ticket 0031 chose
// shapes over `Canvas` for exactly this: here the distinction is in the type system, and
// in a `Canvas` both are calls on the same context.

/// The whole block under the Working Weight: the drawing, the caption, and the
/// `≈ CLOSEST` line where the rack cannot build the number (§5.4).
struct PlateBreakdownView: View {
    let breakdown: PlateBreakdown
    let exercise: ResolvedExercise
    /// What the drawing was solved at — the One-off Weight where there is one, otherwise
    /// the Working Weight. `StackLoad` does not carry it back, and `≈ CLOSEST` has to
    /// name the gap against the number the user is actually lifting today.
    let performedAt: Weight?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            drawing
                .frame(maxWidth: .infinity)
                .frame(height: 118)
            caption
            ClosestLine(breakdown: breakdown, performedAt: performedWeight)
        }
    }

    @ViewBuilder
    private var drawing: some View {
        switch breakdown {
        case .bar(let load): LoadedBar(load: load)
        case .stack(let load): LoadedStack(load: load)
        case .dumbbell: SteelDumbbell()
        case .bodyweight(_, let plates): BeltPlate(plates: plates)
        }
    }

    // MARK: - The caption (§5.5)

    /// What goes on, big; the sum under it, small. §5.5 fixes both halves per Equipment
    /// Type, and the **Base Weight lives here and not in the drawing** — one drawing
    /// serves all three plate-loaded types, and the base is the only difference between
    /// them.
    ///
    /// **Ticket 0053 promoted this block**, on Rob's own words at the walk: *"Ik wil de
    /// '11.3 base + 20 + 5 + 2.5' wat nu in het klein staat veel zichtbaarder. Dat is wat
    /// ik handig vind om te zien."* The strings are §5.5's, unchanged. What changed is the
    /// size and the arrangement: the two halves **stack** instead of sitting side by side,
    /// because at a size worth reading across a gym they do not both fit one line on a
    /// 390 pt phone.
    ///
    /// **The loud half is the one that says what to hang, and that is not the same side
    /// for every type.** A bar and a stack carry it on §5.5's left — the plates, the pin.
    /// A Dumbbell and a belt carry it on the right, and their left is only a qualifier
    /// (`each hand` loads nothing). So the two are named by job below rather than by side.
    private var caption: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(loadLine)
                .typography(Typography.listValue(17))
                .foregroundStyle(Color.text)
                .lineLimit(1)
                // A six-plate bar is twice the width of Rob's. It shrinks rather than
                // wraps: a load line that reflows changes this block's height between
                // Exercises, and every Set row under it would move with it.
                .minimumScaleFactor(0.6)
            Text(qualifierLine)
                .typography(Typography.meta(11))
                .foregroundStyle(Color.dimText)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// The half that says what to load.
    private var loadLine: String {
        switch breakdown {
        case .bar, .stack: captionLeft
        case .dumbbell, .bodyweight: captionRight
        }
    }

    /// The half that qualifies it — the per-side sum, or `each hand`.
    private var qualifierLine: String {
        switch breakdown {
        case .bar, .stack: captionRight
        case .dumbbell, .bodyweight: captionLeft
        }
    }

    private var captionLeft: String {
        switch breakdown {
        case .bar(let load):
            var parts: [String] = []
            // A Barbell prints no Base Weight at all — the bar is standard (§2.6, §5.5).
            if load.printsBaseWeight { parts.append("\(load.baseWeight.decimalString) base") }
            parts.append(contentsOf: load.plates.map(\.decimalString))
            return parts.isEmpty ? "no plates" : parts.joined(separator: " + ")

        case .stack(let load):
            var line = "pin at \(load.blocks) × \(load.stackStep.decimalString) \(load.stackStep.unit.rawValue)"
            let hanging = load.pinRemainder.count + load.microloadPlates.count
            if hanging > 0 { line += " · \(hanging) microplate\(hanging == 1 ? "" : "s")" }
            return line

        case .dumbbell:
            return "each hand"

        case .bodyweight:
            return "added weight only"
        }
    }

    private var captionRight: String {
        switch breakdown {
        case .bar(let load):
            return "\(load.perSide.decimalString) \(load.perSide.unit.rawValue) per side"

        case .stack(let load):
            // **Never a total** (§5.5): two units stand side by side and Hoppa does not
            // add them up, because nothing converted reaches the screen.
            var line = "\(load.pinWeight.decimalString) \(load.pinWeight.unit.rawValue)"
            for plate in load.pinRemainder { line += " + \(plate.decimalString)" }
            if let micro = load.microload, !micro.isZero {
                line += " + \(micro.decimalString) \(micro.unit.rawValue)"
            }
            return line

        case .dumbbell(let each):
            return "2 × \(each.decimalString) \(each.unit.rawValue)"

        case .bodyweight(let added, let plates):
            let unit = added.unit.rawValue
            return plates.count == 1
                ? "1 × \(added.decimalString) \(unit) on the belt"
                : "\(added.decimalString) \(unit) on the belt"
        }
    }

    private var performedWeight: Weight {
        performedAt ?? exercise.workingWeight ?? .zero(exercise.unit)
    }
}

// MARK: - The unreachable weight (§5.4)

/// **The big number never moves to fit the rack** (§5.4). Only this line deals with the
/// gap, and its chip is steel and never a plate colour.
///
/// Its own view since ticket 0037, because the weight sheet needs it too: the number
/// being typed there is not yet the Working Weight, and the one thing the user must be
/// told about it is that the rack cannot build it. One copy of §5.4, two callers.
///
/// Draws nothing at all when the rack builds the weight exactly, which is the common case.
struct ClosestLine: View {
    let breakdown: PlateBreakdown
    /// The weight the breakdown was solved at. A `StackLoad` does not carry it back, and
    /// the gap has to be named against the number the user is actually lifting.
    let performedAt: Weight

    var body: some View {
        if let gap {
            HStack(spacing: 9) {
                Chip("≈ closest", tone: .steel)
                Text(text(gap))
                    .typography(Typography.meta(11))
                    .foregroundStyle(Color.dimText)
            }
        }
    }

    private var gap: (loaded: Weight, difference: Weight)? {
        switch breakdown {
        case .bar(let load):
            return load.isExact ? nil : (load.loadedTotal, load.difference)
        case .stack(let load):
            guard !load.isExact else { return nil }
            let loaded = load.pinRemainder.reduce(load.pinWeight, +)
            return (loaded, loaded - performedAt.relabelled(loaded.unit))
        case .dumbbell, .bodyweight:
            return nil
        }
    }

    private func text(_ gap: (loaded: Weight, difference: Weight)) -> String {
        let over = gap.difference.hundredths > 0
        let size = Weight(hundredths: abs(gap.difference.hundredths), unit: gap.difference.unit)
        return "you load \(gap.loaded.decimalString) \(gap.loaded.unit.rawValue) · "
            + "\(size.decimalString) \(over ? "over" : "under")"
    }
}

// MARK: - The loaded bar (§7.5)

/// Collar, plates, sleeve stop, knurled shaft, and the mirror of it.
///
/// **Plates run smallest outermost**, mirrored — ticket 0031's own line. §5.5's "biggest
/// plate first" is the *loading* order, which is what `BarLoad.plates` holds; the drawing
/// reverses it, because the biggest plate ends up against the shaft.
struct LoadedBar: View {
    let load: BarLoad

    private var ascending: [Weight] { load.plates.reversed() }

    /// Every part's width is known before layout, so the bar shrinks to fit rather than
    /// clipping when a heavy lift puts five plates a side on a 390 pt phone.
    private var naturalWidth: CGFloat {
        let plates = ascending.reduce(CGFloat(0)) { $0 + CGFloat(PlateGlyph.size(for: $1).width) }
        let parts = CGFloat(ascending.count * 2 + 3)    // plates, 2 stops, shaft
        return stopWidth * 2 + shaftWidth + plates * 2 + (parts - 1) * gap
    }

    private let gap: CGFloat = 4
    private let stopWidth: CGFloat = 6
    private let shaftWidth: CGFloat = 100

    var body: some View {
        GeometryReader { geometry in
            let scale = min(1, geometry.size.width / max(naturalWidth, 1))
            ZStack {
                sleeve
                HStack(spacing: gap) {
                    ForEach(Array(ascending.enumerated()), id: \.offset) { _, plate in
                        PlateFace(weight: plate)
                    }
                    sleeveStop
                    KnurledShaft().stroked().frame(width: shaftWidth, height: 14)
                    sleeveStop
                    ForEach(Array(ascending.reversed().enumerated()), id: \.offset) { _, plate in
                        PlateFace(weight: plate)
                    }
                }
            }
            .frame(width: naturalWidth, height: geometry.size.height)
            .scaleEffect(scale)
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }

    /// The sleeve running under the plates. Steel, so it is a border and not a fill.
    private var sleeve: some View {
        RoundedRectangle(cornerRadius: 2)
            .stroke(Color.shaft, lineWidth: 1)
            .frame(height: 9)
    }

    /// **There is no collar.** Ticket 0053, and Rob's own words at the walk: *"dat laatste
    /// dingentje (zwart dingetje) lijkt ook net een plate. die mag weg."* It was an 8 × 40
    /// outline outboard of the last plate, in the darkest steel on the ramp
    /// (`lightness: 0.453`) — plate-shaped, plate-sized, and sitting exactly where a fifth
    /// plate would. §7.1 rule 2 says steel is never filled, which is what should have kept
    /// the two apart, and on a phone at arm's length it did not: a thin dark outline beside
    /// four filled plates reads as one more plate, not as hardware.
    ///
    /// Nothing is lost by dropping it. §7.5 asks for *plates, mirrored around a knurled
    /// centre shaft* and names no collar; the sleeve stops stay, and they are the parts that
    /// say where the loading zone ends. `Color.collar` stays in the palette — the Dumbbell's
    /// sleeve still wears it, where there is no plate anywhere near it to be confused with.

    private var sleeveStop: some View {
        RoundedRectangle(cornerRadius: 1)
            .stroke(Color.sleeveStop, lineWidth: 1)
            .frame(width: stopWidth, height: 46)
    }
}

/// One plate, face on: §7.1 rule 1 in two dimensions — the colour from `PlatePalette` and
/// the size from `PlateGlyph`, and neither alone carries the weight.
///
/// An lbs rack has no palette (§7.3), so it falls back to steel — and steel is never
/// filled, so an lbs plate is a hollow outline. That is the rule reading correctly rather
/// than an omission: the sizes still separate the plates, which is rule 1's own claim.
struct PlateFace: View {
    let weight: Weight

    var body: some View {
        let size = PlateGlyph.size(for: weight)
        let face = Color(plateHex: PlatePalette.hex(for: weight))
        Group {
            if let face {
                RoundedRectangle(cornerRadius: 2)
                    .fill(face)
                    .overlay(
                        RoundedRectangle(cornerRadius: 2)
                            .stroke(
                                Color(plateRimHex: PlatePalette.hex(for: weight)) ?? face,
                                lineWidth: 1))
            } else {
                RoundedRectangle(cornerRadius: 2)
                    .stroke(Color.steel, lineWidth: 1)
            }
        }
        .frame(width: CGFloat(size.width), height: CGFloat(size.height))
    }
}

/// The knurl: an outline with vertical scoring inside it. One `Path`, stroked once, so
/// §7.1 rule 2 holds for the whole shaft.
struct KnurledShaft: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addRoundedRect(in: rect, cornerSize: CGSize(width: 2, height: 2))
        var x = rect.minX + 4
        while x < rect.maxX - 2 {
            path.move(to: CGPoint(x: x, y: rect.minY + 3))
            path.addLine(to: CGPoint(x: x, y: rect.maxY - 3))
            x += 4
        }
        return path
    }
}

extension KnurledShaft {
    // A `Shape` is a view that fills by default, and this one must not.
    fileprivate func stroked() -> some View { stroke(Color.knurlHigh, lineWidth: 1) }
}

// MARK: - The stack (§5.5)

/// The stack as blocks, the pin below the last loaded one, and everything hanging on the
/// pin beside it.
///
/// **The pin lifts everything above it**, so the loaded blocks are the top ones — the
/// prototype's own note, and the one thing about a stack that a reader gets backwards.
struct LoadedStack: View {
    let load: StackLoad

    private let totalBlocks = 14
    private let blockWidth: CGFloat = 74
    private let blockHeight: CGFloat = 5

    private var loaded: Int { max(0, min(load.blocks, totalBlocks)) }

    /// Everything the pin carries: the same-unit remainder the pin cannot reach, and the
    /// Microload where the units differ. Ticket 0031 settled that these hang in the same
    /// place, so they draw in the same place.
    private var hanging: [Weight] { load.pinRemainder + load.microloadPlates }

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                ForEach(1...totalBlocks, id: \.self) { index in
                    block(isLoaded: index <= loaded)
                        .overlay(alignment: .leading) {
                            if index == loaded { pin }
                        }
                }
            }
            VStack(spacing: 3) {
                ForEach(Array(hanging.enumerated()), id: \.offset) { _, plate in
                    PlateFace(weight: plate)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func block(isLoaded: Bool) -> some View {
        RoundedRectangle(cornerRadius: 1)
            .stroke(isLoaded ? Color.steel : Color.stackEmpty, lineWidth: 1)
            .frame(width: blockWidth, height: blockHeight)
    }

    /// The pin sits **below** the last loaded block and sticks out past the stack, which
    /// is how a reader tells the loaded half from the empty half at a glance.
    private var pin: some View {
        RoundedRectangle(cornerRadius: 1)
            .stroke(Color.pin, lineWidth: 1)
            .frame(width: blockWidth + 22, height: 3)
            .offset(x: -11, y: blockHeight / 2 + 1)
    }
}

// MARK: - The dumbbell and the belt (§5.5)

/// **No plate colours — nothing is loaded** (§5.5). All steel, so all outline.
struct SteelDumbbell: View {
    var body: some View {
        HStack(spacing: 4) {
            bell
            sleeve
            KnurledShaft().stroked().frame(width: 70, height: 14)
            sleeve
            bell
        }
        .frame(maxWidth: .infinity)
    }

    private var bell: some View {
        RoundedRectangle(cornerRadius: 2)
            .stroke(Color.sleeveStop, lineWidth: 1)
            .frame(width: 26, height: 84)
    }

    private var sleeve: some View {
        RoundedRectangle(cornerRadius: 2)
            .stroke(Color.collar, lineWidth: 1)
            .frame(width: 16, height: 60)
    }
}

/// The added plate face-on, hanging from a belt clip (§5.5). The strap and the clip are
/// steel; the plate is a plate.
struct BeltPlate: View {
    let plates: [Weight]

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .stroke(Color.sleeveStop, lineWidth: 1)
                .frame(width: 2, height: 18)
            Circle()
                .stroke(Color.sleeveStop, lineWidth: 1.5)
                .frame(width: 13, height: 13)
            HStack(spacing: 4) {
                ForEach(Array(plates.enumerated()), id: \.offset) { _, plate in
                    PlateDisc(weight: plate)
                }
            }
            .padding(.top, 2)
        }
        .frame(maxWidth: .infinity)
    }
}

/// A plate seen face-on: a disc with the bar's hole in it, rather than the edge-on
/// rectangle a loaded bar draws.
struct PlateDisc: View {
    let weight: Weight

    var body: some View {
        let diameter = CGFloat(min(PlateGlyph.size(for: weight).height * 0.62, 72))
        let face = Color(plateHex: PlatePalette.hex(for: weight))
        ZStack {
            if let face {
                Circle()
                    .fill(face)
                    .overlay(
                        Circle().stroke(
                            Color(plateRimHex: PlatePalette.hex(for: weight)) ?? face,
                            lineWidth: 1))
            } else {
                Circle().stroke(Color.steel, lineWidth: 1)
            }
            Circle()
                .fill(Color.floor)
                .frame(width: diameter * 0.28, height: diameter * 0.28)
        }
        .frame(width: diameter, height: diameter)
    }
}
