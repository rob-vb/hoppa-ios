import Testing
@testable import HoppaRules

/// `SPEC.md` §6.5 — "Which plates a burst throws", and §8.2's first summary defect.
///
/// The prototype's `colours()` fell back to the Increment plate for every Equipment
/// Type that is not plate-loaded. Every test here fails against it.
@Suite("SPEC.md §6.5 — the burst throws what the Plate Breakdown draws")
struct BurstTests {

    // MARK: - Bar

    @Test("A bar throws its per-side plates, and never the Base Weight")
    func barThrowsPerSidePlatesOnly() {
        // 75 kg on a 20 kg Smith bar: 27.5 per side = 20 + 5 + 2.5.
        let load = BarLoad(
            baseWeight: kg("20"), printsBaseWeight: true, perSide: kg("27.5"),
            plates: [kg("20"), kg("5"), kg("2.5")], isExact: true,
            loadedTotal: kg("75"), difference: kg("0"))

        #expect(Rules.burstSource(.bar(load)) == [.plate(kg("20")), .plate(kg("5")), .plate(kg("2.5"))])
        // The 20 kg bar is drawn as a shaft, not a plate, so it is not in the list.
        #expect(!Rules.burstSource(.bar(load)).contains(.steel))
    }

    @Test("Sampling is proportional by plate count, not by distinct size")
    func samplingIsProportionalByCount() {
        // 20 + 10 + 2.5 + 2.5 per side: half the list is grey (§6.5).
        let load = BarLoad(
            baseWeight: kg("20"), printsBaseWeight: false, perSide: kg("35"),
            plates: [kg("20"), kg("10"), kg("2.5"), kg("2.5")], isExact: true,
            loadedTotal: kg("90"), difference: kg("0"))
        let source = Rules.burstSource(.bar(load))

        #expect(source.count == 4)
        #expect(source.filter { $0 == .plate(kg("2.5")) }.count == 2)
        // One share per distinct size would give three entries and make the pair of
        // 2.5s a third of the burst instead of a half — the rejected rule.
        #expect(Set(source).count == 3)
    }

    @Test("An empty bar still lands: it throws steel rather than nothing")
    func emptyBarThrowsSteel() {
        // The Working Weight is the bar itself. The row still went up, and §6.5
        // rejected throwing nothing, because the count is the hero.
        let load = BarLoad(
            baseWeight: kg("20"), printsBaseWeight: false, perSide: kg("0"),
            plates: [], isExact: true, loadedTotal: kg("20"), difference: kg("0"))

        #expect(Rules.burstSource(.bar(load)) == [.steel])
    }

    // MARK: - Stack — §8.2 summary defect 1

    @Test("A stack throws one steel slab per loaded block, plus what hangs on the pin")
    func stackThrowsBlocksAndPin() {
        // 100 lbs on a 10 lbs stack, with a 1.25 kg Microload hanging on the pin.
        let load = StackLoad(
            blocks: 10, stackStep: lbs("10"), pinWeight: lbs("100"), pinRemainder: [],
            isExact: true, microload: kg("1.25"), microloadPlates: [kg("1.25")])
        let source = Rules.burstSource(.stack(load))

        #expect(source.filter { $0 == .steel }.count == 10)
        #expect(source.filter { $0 == .plate(kg("1.25")) }.count == 1)
        #expect(source.count == 11)
    }

    @Test("The same-unit remainder hangs on the pin too, so it throws")
    func stackThrowsItsSameUnitRemainder() {
        // 27.5 kg on a 5 kg stack: the pin takes 25, and 2.5 hangs on it.
        let load = StackLoad(
            blocks: 5, stackStep: kg("5"), pinWeight: kg("25"), pinRemainder: [kg("2.5")],
            isExact: true, microload: nil, microloadPlates: [])
        let source = Rules.burstSource(.stack(load))

        #expect(source.filter { $0 == .plate(kg("2.5")) }.count == 1)
        #expect(source.filter { $0 == .steel }.count == 5)
    }

    // MARK: - Dumbbell and Bodyweight — §8.2 summary defect 1

    @Test("A dumbbell throws steel, never the Increment plate")
    func dumbbellThrowsSteel() {
        // The prototype threw `[added]` here — a colour §5.5 does not draw.
        #expect(Rules.burstSource(.dumbbell(each: kg("22.5"))) == [.steel])
    }

    @Test("Bodyweight throws the plate on the belt")
    func bodyweightThrowsTheBeltPlate() {
        #expect(Rules.burstSource(.bodyweight(added: kg("15"), plates: [kg("15")]))
            == [.plate(kg("15"))])
    }

    @Test("Bodyweight with nothing on the belt still lands")
    func bodyweightWithNoPlateThrowsSteel() {
        #expect(Rules.burstSource(.bodyweight(added: kg("0"), plates: [])) == [.steel])
    }

    // MARK: - The burst matches the drawing, particle for plate

    @Test("Every Equipment Type in the Program throws what its own breakdown draws")
    func theBurstMatchesTheDrawingOnEveryType() {
        let book = upperALogbook()

        for exercise in book.allExercises.compactMap({ book.resolvedExercise($0.id) }) {
            guard let drawn = Rules.breakdown(for: exercise, inventory: book.plateInventory)
            else { continue }
            let source = Rules.burstSource(drawn)

            // Never empty: every Went-up row lands.
            #expect(!source.isEmpty, Comment(rawValue: exercise.equipment.rawValue + " threw nothing"))

            // Every plate thrown is a plate the drawing holds.
            let drawnPlates: [Weight] = switch drawn {
            case .bar(let l): l.plates
            case .stack(let l): l.pinRemainder + l.microloadPlates
            case .dumbbell: []
            case .bodyweight(_, let p): p
            }
            for particle in source {
                if case .plate(let w) = particle {
                    #expect(drawnPlates.contains(w), Comment(rawValue: exercise.equipment.rawValue + " threw an undrawn " + w.decimalString))
                }
            }
        }
    }
}
