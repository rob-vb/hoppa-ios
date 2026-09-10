import Foundation
import Testing
import HoppaRules

@Suite("Sticker — tenths, half away from zero")
struct StickerTests {

    @Test("The printed kg column on an lbs stack")
    func thePhotoColumn() {
        #expect(Sticker(of: lbs("2.5"), readIn: .kg)?.decimalString == "1.1")
        #expect(Sticker(of: lbs("5"), readIn: .kg)?.decimalString == "2.3")
        #expect(Sticker(of: lbs("10"), readIn: .kg)?.decimalString == "4.5")
        #expect(Sticker(of: lbs("15"), readIn: .kg)?.decimalString == "6.8")
        #expect(Sticker(of: lbs("85"), readIn: .kg)?.decimalString == "38.6")
        #expect(Sticker(of: lbs("190"), readIn: .kg)?.decimalString == "86.2")
    }

    @Test("A pin plate rounds to the whole kg printed on the stack")
    func pinColumnIsOnes() {
        #expect(Sticker.ones(of: lbs("190"), readIn: .kg)?.decimalString == "86")
        #expect(Sticker.ones(of: lbs("195"), readIn: .kg)?.decimalString == "88")
        #expect(Sticker.ones(of: lbs("200"), readIn: .kg)?.decimalString == "91")
        #expect(Sticker.ones(of: lbs("10"), readIn: .kg)?.decimalString == "5")
        #expect(Sticker.ones(of: lbs("15"), readIn: .kg)?.decimalString == "7")
    }

    @Test("Ones that round past tenths are not a pin you can set")
    func settableColumnsDropOnesUp() {
        let ten = Sticker.settableColumns(of: lbs("10"), readIn: .kg)
        #expect(ten.map(\.decimalString) == ["4.5"])
        let oneTwentyFive = Sticker.settableColumns(of: lbs("125"), readIn: .kg)
        #expect(oneTwentyFive.map(\.decimalString) == ["56.7"])
        let oneSeventyFive = Sticker.settableColumns(of: lbs("175"), readIn: .kg)
        #expect(oneSeventyFive.map(\.decimalString) == ["79.4", "79"])
        let oneNinety = Sticker.settableColumns(of: lbs("190"), readIn: .kg)
        #expect(oneNinety.map(\.decimalString) == ["86.2", "86"])
        let oneThirty = Sticker.settableColumns(of: lbs("130"), readIn: .kg)
        #expect(oneThirty.map(\.decimalString) == ["59"])
    }

    @Test("Same-unit sticker is tenths of the original")
    func sameUnit() {
        #expect(Sticker(of: kg("2.5"), readIn: .kg)?.decimalString == "2.5")
        #expect(Sticker(of: lbs("10"), readIn: .lbs)?.decimalString == "10")
    }
}
