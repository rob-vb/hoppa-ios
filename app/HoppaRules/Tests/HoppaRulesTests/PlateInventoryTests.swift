import Testing
import HoppaRules

/// §5.2's footer, which is the one number the Plate Inventory screen computes.
///
/// It is a rule by the map's `is-this-a-rule` test — it falls out of the Logbook alone,
/// and two lifters holding the same rack must read the same jump — so it is tested here
/// rather than left in a view where nothing can run it.
@Suite("The smallest jump on the bar (§5.2)")
struct PlateInventoryTests {

    /// The shipped kg rack: 1.25 kg is the smallest normal plate, and a bar takes one
    /// per side. §5.2 prints exactly this number.
    @Test("A fresh kg rack jumps 2.5 kg")
    func standardKg() {
        let rack = PlateInventory.standard(.kg)
        #expect(rack.smallestJumpOnTheBar(for: .progressiveOverload) == kg("2.5"))
    }

    /// Every Microplate ships off, so the footer's second clause is absent on a fresh
    /// install — and `nil` is how a view is told there is nothing true to print.
    @Test("A fresh kg rack has no Microloading jump")
    func standardKgHasNoMicroplate() {
        let rack = PlateInventory.standard(.kg)
        #expect(rack.smallestJumpOnTheBar(for: .microloading) == kg("2.5"),
                "with no Microplate on, Microloading reaches for the same 1.25 kg plate")
        #expect(rack.enabledMicroplates.isEmpty,
                "which is what the screen asks before it prints the second clause")
    }

    /// §5.2's worked example: switch the 0.25 on and the footer gains `· 0.5 kg`.
    @Test("The smallest Microplate on makes it 0.5 kg")
    func microplateOn() {
        var rack = PlateInventory.standard(.kg)
        rack.setPlate(kg("0.25"), on: true)
        #expect(rack.smallestJumpOnTheBar(for: .microloading) == kg("0.5"))
        #expect(rack.smallestJumpOnTheBar(for: .progressiveOverload) == kg("2.5"),
                "§5.3: a Progressive Overload solve never reaches for a Microplate")
    }

    /// It is the **smallest** owned Microplate that sets the jump, not the one switched
    /// on last.
    @Test("Two Microplates on: the smaller wins")
    func theSmallerMicroplateWins() {
        var rack = PlateInventory.standard(.kg)
        rack.setPlate(kg("1"), on: true)
        rack.setPlate(kg("0.5"), on: true)
        #expect(rack.smallestJumpOnTheBar(for: .microloading) == kg("1"))
    }

    /// The lbs rack ships 2.5 lbs as its smallest normal plate.
    @Test("A fresh lbs rack jumps 5 lbs")
    func standardLbs() {
        let rack = PlateInventory.standard(.lbs)
        #expect(rack.smallestJumpOnTheBar(for: .progressiveOverload) == lbs("5"))
    }

    /// The empty rack. §5.2's footer states **only what is true**, so a screen with no
    /// plate switched on has no jump to print — and it must not print zero, which would
    /// read as a rack that moves in steps of nothing.
    @Test("Every plate off: no jump at all")
    func nothingSwitchedOn() {
        var rack = PlateInventory.standard(.kg)
        for plate in rack.plates { rack.setPlate(plate.weight, on: false) }
        #expect(rack.smallestJumpOnTheBar(for: .progressiveOverload) == nil)
        #expect(rack.smallestJumpOnTheBar(for: .microloading) == nil)
    }
}
