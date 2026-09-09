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
    }

    @Test("Same-unit sticker is tenths of the original")
    func sameUnit() {
        #expect(Sticker(of: kg("2.5"), readIn: .kg)?.decimalString == "2.5")
        #expect(Sticker(of: lbs("10"), readIn: .lbs)?.decimalString == "10")
    }
}
