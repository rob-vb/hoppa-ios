import Testing
import HoppaRules

@Suite("StackLadder — affine first + step")
struct StackLadderTests {

    @Test("The photo machine: 15 lbs per plate, top plate reads 25")
    func thePhotoMachine() {
        let ladder = StackLadder(step: lbs("15"), first: lbs("25"))!
        #expect(!ladder.startsFromZero)
        #expect(ladder.unit == .lbs)
        #expect(ladder.pinColumnIsOnes)

        let at70 = ladder.pin(atOrUnder: lbs("70"))
        #expect(at70?.plate == 4)
        #expect(at70?.label == lbs("70"))

        let at72 = ladder.pin(atOrUnder: lbs("72"))
        #expect(at72?.plate == 4)
        #expect(at72?.label == lbs("70"))

        #expect(ladder.pin(atOrUnder: lbs("20")) == nil)

        let at25 = ladder.pin(atOrUnder: lbs("25"))
        #expect(at25?.plate == 1)
        #expect(at25?.label == lbs("25"))
    }

    @Test("A nil first plate is a from-zero stack")
    func nilFirstIsTheStep() {
        let ladder = StackLadder(step: lbs("10"), first: nil)!
        #expect(ladder.startsFromZero)
        #expect(ladder.first == lbs("10"))
        #expect(!ladder.pinColumnIsOnes)

        let pin = ladder.pin(atOrUnder: lbs("105"))
        #expect(pin?.plate == 10)
        #expect(pin?.label == lbs("100"))
    }
}
