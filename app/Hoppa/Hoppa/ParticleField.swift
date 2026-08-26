import Foundation

// Ticket 0039 — the Ignition burst, as arithmetic.
//
// **The drawing is in `Confetti.swift`; the physics is here**, and the split is the one
// the map keeps making: a file that imports no SwiftUI can be built and run on the VPS,
// and a file that draws cannot ([The Logbook on disk](0025-the-logbook-on-disk.md)). So
// gravity, drag, spin, the sampling and the culling are all proven here before the Mac
// ever sees them, and `Confetti.swift` is left with nothing but `fill` and `stroke`.
//
// It is **not** a rule, and it must not become one: which plates a burst throws is
// decided by the `Logbook` and lives in `HoppaRules.burstSource(_:)`, while the arc each
// particle takes is random by design (`SPEC.md` §6.5, ticket 0031). This file is the
// random half. It never sees a `Weight` — the view resolves the sampling list into
// `ConfettiSlab`s first, so nothing here can invent a plate colour.
//
// `Foundation` for `cos`/`sin` only. Ticket 0031 learned that libm is not linked without
// it, which is a fact about a *view* file being provable here, not about a rule.

/// What a particle is painted with. **Two cases, because §7.1 rule 2 has two cases**: a
/// plate is a filled shape, and steel is never filled.
///
/// The view maps `HoppaRules.BurstParticle` onto this, and that map is where §7.3's
/// "kg only" falls out — an lbs plate has no colour, so it throws steel, exactly as the
/// Went-up chip beside it already does.
enum ConfettiSlab: Sendable, Hashable {
    /// `#RRGGBB`, the plate's face. The rim is derived from it (`Color(plateRimHex:)`).
    case plate(faceHex: String)
    /// Hollow — a 1 px outline, **without exception** (§6.5). A filled steel slab at
    /// 5 x 14 px is nearly the 1.25 kg grey `#70767C`, so a Dumbbell burst would read as
    /// a rack of 1.25s.
    case steel
}

/// One slab in flight. Plate-shaped, because §6.5 asks for the same glyph the Inventory
/// and the rows draw — a small vertical slab with a 2 pt radius.
struct ConfettiParticle {
    var x: Double
    var y: Double
    var vx: Double
    var vy: Double
    var width: Double
    var height: Double
    var rotation: Double
    var spin: Double
    var slab: ConfettiSlab
    /// Steps survived. The second half of the cull, so a particle drifting sideways
    /// forever still leaves.
    var steps: Int
}

/// The cloud, stepped at a fixed rate.
///
/// **The step is fixed at 1/60 s and the clock is real time.** The prototype's constants
/// are per-frame (`vy += .42`, `vx *= .992`) and its browser ran at 60 Hz; a 120 Hz phone
/// stepping those once per frame falls twice as fast. `advance(by:)` takes the seconds
/// that actually passed and runs whole 1/60 steps, so the burst lasts the same 1.4 s on
/// any display.
struct ParticleField {

    // MARK: - Variant C's constants (ticket 0031, `SPEC.md` §6.5)

    /// One fixed physics step.
    static let stepSeconds: Double = 1.0 / 60

    /// Rows land 190 ms apart, and the sequence is what makes the count *a count you
    /// watch land*. It stays under Reduce Motion; only the particles go.
    static let rowInterval: Double = 0.190

    /// ~15 particles per Went-up row. **A weak burst is fixed with more particles, never
    /// with lighter ones** (§6.5) — the face is the weight.
    static let perBurst: Int = 15

    static let power: Double = 7.4
    static let spread: Double = Double.pi * 0.95
    static let gravity: Double = 0.42
    static let drag: Double = 0.992
    static let spin: Double = 0.17
    /// The slab, in points: 5-9 wide, 14-27 tall.
    static let slabWidth: ClosedRange<Double> = 5...9
    static let slabHeight: ClosedRange<Double> = 14...27
    /// The last stretch of the canvas, over which a particle fades out rather than
    /// hard-clipping at the edge.
    static let fadeDepth: Double = 140
    /// Roughly seven seconds. Nothing should reach it; it is the backstop.
    static let maxSteps: Int = 420

    private(set) var particles: [ConfettiParticle] = []

    /// Left-over real time, under one step.
    private var carry: Double = 0

    /// Nothing left in the air. The screen is quiet and every number is readable.
    var isQuiet: Bool { particles.isEmpty }

    init() {}

    // MARK: - Firing

    /// Throw `perBurst` particles from a rectangle — **the row's own plate chip**.
    ///
    /// `slabs` is `Rules.burstSource(_:)`'s sampling list, one entry per plate in the
    /// load, and this picks from it **uniformly**. That is what makes §6.5's *proportional
    /// by plate count* come out for free: `20 + 10` per side throws half blue and half
    /// green because the list holds one of each, and no weighting happens here.
    ///
    /// An empty list throws nothing, but the rules never hand one over — `burstSource`
    /// answers `[.steel]` for a load with no plates, because **every Went-up row must
    /// land**.
    mutating func burst<G: RandomNumberGenerator>(
        fromChip chip: (x: Double, y: Double, width: Double, height: Double),
        throwing slabs: [ConfettiSlab],
        count: Int = ParticleField.perBurst,
        using rng: inout G
    ) {
        guard !slabs.isEmpty else { return }
        for _ in 0..<count {
            // Straight up, then fanned. The spread is just under a half-circle, so a
            // particle can leave sideways but never downwards.
            let angle = -Double.pi / 2 + (Double.random(in: 0...1, using: &rng) - 0.5) * Self.spread
            let speed = Self.power * (0.55 + Double.random(in: 0...1, using: &rng) * 0.8)
            // Spawned across the chip itself — 9 x 34 pt — and not across the prototype's
            // 34 x 12 box, which is variant B's point-source jitter left in place. §6.5
            // says the burst comes from the chip, and this is the chip.
            particles.append(ConfettiParticle(
                x: chip.x + Double.random(in: 0...1, using: &rng) * chip.width,
                y: chip.y + Double.random(in: 0...1, using: &rng) * chip.height,
                vx: cos(angle) * speed,
                vy: sin(angle) * speed,
                width: Double.random(in: Self.slabWidth, using: &rng),
                height: Double.random(in: Self.slabHeight, using: &rng),
                rotation: Double.random(in: 0...Double.pi, using: &rng),
                spin: (Double.random(in: 0...1, using: &rng) - 0.5) * 2 * Self.spin,
                slab: slabs[Int.random(in: 0..<slabs.count, using: &rng)],
                steps: 0))
        }
    }

    // MARK: - Flying

    /// Step the cloud forward by the real seconds that passed, then drop what has left.
    ///
    /// `height` is the canvas, so the floor moves with the phone rather than sitting at
    /// the prototype's hard-coded 844.
    mutating func advance(by seconds: Double, height: Double) {
        guard !particles.isEmpty else {
            carry = 0
            return
        }
        // A backgrounded screen comes back with a large gap. Simulating it would fling
        // the cloud through the floor in one frame, so the gap is dropped: at most four
        // steps per call, and the rest of the time is thrown away.
        carry = min(carry + max(0, seconds), Self.stepSeconds * 4)
        while carry >= Self.stepSeconds {
            carry -= Self.stepSeconds
            step()
        }
        // One slab-height of slack, so nothing pops while it is still half visible.
        let floor = height + Self.slabHeight.upperBound
        particles.removeAll { $0.y > floor || $0.steps >= Self.maxSteps }
    }

    private mutating func step() {
        for index in particles.indices {
            particles[index].vy += Self.gravity
            particles[index].vx *= Self.drag
            particles[index].vy *= Self.drag
            particles[index].x += particles[index].vx
            particles[index].y += particles[index].vy
            particles[index].rotation += particles[index].spin
            particles[index].steps += 1
        }
    }

    /// How solid a particle is at its depth: full until the last `fadeDepth` points of
    /// the canvas, then out by the bottom edge. Nothing hard-clips.
    static func opacity(y: Double, height: Double) -> Double {
        guard y > height - fadeDepth else { return 1 }
        return max(0, min(1, (height - y) / fadeDepth))
    }

    /// Everything the field can hold, cleared. Called when the screen goes.
    mutating func clear() {
        particles.removeAll()
        carry = 0
    }
}
