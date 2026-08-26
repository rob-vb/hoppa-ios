import SwiftUI
import HoppaRules

// Ticket 0039 — the Ignition burst, drawn.
//
// **One `Canvas` inside `TimelineView(.animation)`**, settled at
// [Drawing the loaded bar and the Ignition confetti](0031-drawing-the-bar-and-the-confetti.md),
// and it is the reverse of the bar's answer for the same reason read twice: `Canvas`
// gives you a draw call and takes away layout. The bar is layout and no animation; this
// is animation and no layout. Up to ~75 slabs go down in one pass with no view identity
// to maintain, and `SpriteKit`, `CAEmitterLayer` and one view per particle were all
// rejected there by name.
//
// Everything that can be checked without a Mac is in `ParticleField.swift`. What is left
// here is the two lines §7.1 rule 2 turns on — **a plate is filled and steel never is** —
// and where the burst comes from.

// MARK: - Where a burst comes from

/// Every Went-up row's plate chip, in the Summary's own coordinate space.
///
/// §6.5 fires each burst **from that row's chip**, so the canvas needs the rectangle the
/// chip actually landed on — which only layout knows. `onGeometryChange` would say this
/// in one line and it is iOS 18; the app ships to iOS 17 (ticket 0018), so it is a
/// preference.
struct ChipFrames: PreferenceKey {
    static var defaultValue: [ExerciseID: CGRect] { [:] }

    static func reduce(value: inout [ExerciseID: CGRect], nextValue: () -> [ExerciseID: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

extension View {
    /// Report this chip's rectangle in the named space the Summary sets up.
    func reportsChipFrame(_ id: ExerciseID, in space: String) -> some View {
        background(
            GeometryReader { proxy in
                Color.clear.preference(
                    key: ChipFrames.self,
                    value: [id: proxy.frame(in: .named(space))])
            })
    }
}

// MARK: - The cloud, held across frames

/// A box around `ParticleField`, because the field is stepped **inside** the render pass
/// and SwiftUI state cannot be written there.
///
/// It is deliberately not `@Observable` and it publishes nothing: `TimelineView` already
/// redraws every frame, so an observation here would only add an invalidation loop on top
/// of a clock that is already ticking.
final class IgnitionField {
    private var field = ParticleField()
    private var lastTick: Date?
    private var rng = SystemRandomNumberGenerator()
    /// `#RRGGBB` parsed once per burst rather than once per particle per frame.
    private var swatches: [String: (face: Color, rim: Color)] = [:]

    /// Where each Went-up row's chip landed, handed down by `overlayPreferenceValue`.
    /// The sequence reads it at the moment a row lands, which is the moment the burst
    /// has to come from the right rectangle.
    var chipFrames: [ExerciseID: CGRect] = [:]

    var isQuiet: Bool { field.isQuiet }

    /// Throw one row's burst. `slabs` is `Rules.burstSource(_:)`'s sampling list.
    ///
    /// No chip, no burst: a row whose rectangle has not been reported yet has not been
    /// laid out, and a burst from `.zero` would come off the top-left corner of the
    /// screen instead of off the plate.
    func burst(from exercise: ExerciseID, throwing slabs: [ConfettiSlab]) {
        guard let chip = chipFrames[exercise] else { return }
        burst(fromChip: chip, throwing: slabs)
    }

    private func burst(fromChip chip: CGRect, throwing slabs: [ConfettiSlab]) {
        for slab in slabs {
            guard case .plate(let hex) = slab, swatches[hex] == nil else { continue }
            swatches[hex] = (
                face: Color(plateHex: hex) ?? .steel,
                // §7.3's rim, one step lighter than the face — 1.5 pt here, so a dark
                // plate reads as a moving ring rather than a hole (§6.5).
                rim: Color(plateRimHex: hex) ?? .steel)
        }
        field.burst(
            fromChip: (x: chip.minX, y: chip.minY, width: chip.width, height: chip.height),
            throwing: slabs,
            using: &rng)
    }

    /// Advance to this frame's date and draw. Called from the `Canvas` renderer.
    func render(_ context: GraphicsContext, size: CGSize, at date: Date) {
        advance(to: date, height: size.height)
        for particle in field.particles {
            var slab = context
            slab.translateBy(x: particle.x, y: particle.y)
            slab.rotate(by: .radians(particle.rotation))
            slab.opacity = ParticleField.opacity(y: particle.y, height: size.height)
            let shape = Path(
                roundedRect: CGRect(
                    x: -particle.width / 2, y: -particle.height / 2,
                    width: particle.width, height: particle.height),
                cornerRadius: 2)   // §7.4's near-square radius

            switch particle.slab {
            case .plate(let hex):
                let swatch = swatches[hex] ?? (face: .steel, rim: .steel)
                slab.fill(shape, with: .color(swatch.face))
                slab.stroke(shape, with: .color(swatch.rim), lineWidth: 1.5)
            case .steel:
                // **Hollow, without exception** (§6.5, §7.1 rule 2). No fill call exists
                // on this branch, which is the point of putting the two cases in the type
                // system rather than in a comment.
                slab.stroke(shape, with: .color(.steel), lineWidth: 1)
            }
        }
    }

    func clear() {
        field.clear()
        lastTick = nil
    }

    private func advance(to date: Date, height: Double) {
        let elapsed = lastTick.map { date.timeIntervalSince($0) } ?? ParticleField.stepSeconds
        lastTick = date
        // A first frame, a resumed clock or a backgrounded screen all arrive as a gap
        // that is not a frame. One step is the honest reading of it.
        let seconds = (elapsed <= 0 || elapsed > 0.5) ? ParticleField.stepSeconds : elapsed
        field.advance(by: seconds, height: height)
    }
}

// MARK: - The canvas

/// The burst, over the whole Summary. It draws nothing when it is not running, and it
/// never takes a tap — `DONE` is under it.
struct IgnitionCanvas: View {
    let field: IgnitionField
    /// False stops the clock. The screen has to be quiet after ~1.4 s (§6.5), and a
    /// `TimelineView` left running would keep waking the phone for an empty draw.
    let running: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: nil, paused: !running)) { timeline in
            Canvas { context, size in
                field.render(context, size: size, at: timeline.date)
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - What a row throws

extension ConfettiSlab {
    /// `HoppaRules.BurstParticle` — **which** plates the burst throws, decided from the
    /// `Logbook` — mapped onto what a particle is painted with.
    ///
    /// §7.3 paints kg only, so a plate the palette has no colour for throws steel. That
    /// is the same fallback the Went-up chip beside it already makes, and §7.1 rule 2
    /// makes it hollow.
    init(_ particle: BurstParticle) {
        switch particle {
        case .plate(let weight):
            if let hex = PlatePalette.hex(for: weight) {
                self = .plate(faceHex: hex)
            } else {
                self = .steel
            }
        case .steel:
            self = .steel
        }
    }
}
