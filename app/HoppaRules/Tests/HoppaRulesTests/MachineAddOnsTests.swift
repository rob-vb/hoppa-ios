import Foundation
import Testing
import HoppaRules

@Suite("MachineAddOns — gym sliders, not rack plates")
struct MachineAddOnsTests {

    @Test("A missing stackAddOns key decodes both ON")
    func missingKeyIsStandard() throws {
        let json = """
            {"unit":"kg","plates":[],"microplates":[]}
            """
        let rack = try JSONDecoder().decode(PlateInventory.self, from: Data(json.utf8))
        #expect(rack.stackAddOns == .standard)
        #expect(rack.stackAddOns.enabledSizes == [lbs("5"), lbs("2.5")])
    }

    @Test("plates(for:) never returns the sliders")
    func addOnsAreNotRackPlates() {
        var rack = PlateInventory.standard(.lbs)
        rack.setPlate(lbs("2.5"), on: false)
        rack.setPlate(lbs("5"), on: false)
        #expect(!rack.plates(for: .progressiveOverload).contains(lbs("2.5")))
        #expect(!rack.plates(for: .progressiveOverload).contains(lbs("5")))
        #expect(rack.stackAddOns.enabledSizes == [lbs("5"), lbs("2.5")])
    }
}
