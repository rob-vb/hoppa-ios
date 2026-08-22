/// What an Ignition burst throws (`SPEC.md` §6.5, "Which plates a burst throws").
///
/// This is a rule and not a drawing. Ticket 31 drew the line: **which plates a burst
/// throws is decided by the `Logbook`, and how a particle looks and moves is not.**
/// Two lifters with the same `Logbook` must watch the same colours come off the same
/// row; the arc each particle takes is random by design, so it stays in the view.
///
/// It exists here because §8.2's first summary defect is exactly this list getting it
/// wrong: `colours()` in `design/0009-summary/fitty-workout-summary.html` falls back to
/// `rack = [added]` — the Increment plate — for every Equipment Type that is not
/// plate-loaded, so a stack threw its Increment and a dumbbell threw a colour it never
/// draws. A test here is what stops that porting forward.
public enum BurstParticle: Sendable, Hashable {
    /// A plate, in its own colour. `PlatePalette.hex(for:)` paints it.
    case plate(Weight)
    /// Steel: a pin block, or the whole dumbbell. **Never filled** (§7.1 rule 2) — a
    /// filled steel slab at 5 x 14 px is nearly the 1.25 kg grey `#70767C`, so a
    /// Dumbbell burst would read as a rack of 1.25s.
    case steel
}

extension Rules {

    /// **The burst throws what the Plate Breakdown draws.** One rule, on every
    /// Equipment Type (`SPEC.md` §6.5).
    ///
    /// Returns the **sampling list**, one entry per plate in the load — not the fifteen
    /// particles. §6.5 fixes the sampling as *proportional by plate count, picked
    /// uniformly*, so `20 + 10` per side throws half blue and half green and
    /// `20 + 10 + 2.5 + 2.5` throws half grey. One share per *distinct size* was
    /// rejected: it gives a lone 1.25 kg the volume of two 20s, so a plate would get
    /// louder as it got smaller, inverting §7.1 rule 1. Proportional by *mass* was
    /// rejected in the other direction — it nearly erases a microplate.
    ///
    /// Keeping the list one-entry-per-plate is what makes uniform picking come out
    /// proportional for free, and it is why the view needs no weighting of its own.
    public static func burstSource(_ breakdown: PlateBreakdown) -> [BurstParticle] {
        let source: [BurstParticle] = switch breakdown {

        // The per-side plates of the new Working Weight, Base Weight excluded. The
        // Base Weight is not drawn as a plate (§5.5 puts it in text), so it throws
        // nothing.
        case .bar(let load):
            load.plates.map(BurstParticle.plate)

        // The Microplates on the pin, plus one steel slab per loaded pin block.
        // Everything hanging on the pin counts: `pinRemainder` is the same-unit part
        // the pin cannot reach and `microloadPlates` is the mixed-unit Microload, and
        // the drawing hangs both in the same place.
        case .stack(let load):
            (load.pinRemainder + load.microloadPlates).map(BurstParticle.plate)
                + Array(repeating: .steel, count: max(0, load.blocks))

        // §5.5 draws the dumbbell in steel and loads nothing on it, so it never throws
        // the Increment plate.
        case .dumbbell:
            [.steel]

        // The plate on the belt.
        case .bodyweight(_, let plates):
            plates.map(BurstParticle.plate)
        }

        // **Every Went-up row must land** (§6.5): throwing nothing was rejected,
        // because the count is the hero. An empty bar — the Working Weight is the bar
        // itself — still has a row, so it throws steel, which is what it draws.
        return source.isEmpty ? [.steel] : source
    }
}
