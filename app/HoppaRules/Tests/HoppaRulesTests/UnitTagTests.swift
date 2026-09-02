import Testing
import HoppaRules

@Suite("UnitTag — what the sheet prints beside Working Weight")
struct UnitTagTests {

    @Test("unitTag: 5 types × nil × both owns × both racks")
    func theTable() {
        for rack in WeightUnit.allCases {
            for own in WeightUnit.allCases {
                #expect(Rules.unitTag(equipment: nil, own: own, rack: rack) == .locked(own))
                for type in EquipmentType.allCases {
                    let expected: UnitTag = type.takesUnitFromInventory
                        ? .locked(rack) : .own(own)
                    #expect(
                        Rules.unitTag(equipment: type, own: own, rack: rack) == expected,
                        "\(type.rawValue) own=\(own.rawValue) rack=\(rack.rawValue)")
                }
            }
        }
        #expect(EquipmentType.allCases.count == 5)
        #expect(EquipmentType.dumbbell.takesUnitFromInventory)
        #expect(!EquipmentType.machineStack.takesUnitFromInventory)
        #expect(EquipmentType.barbell.takesUnitFromInventory)
        #expect(EquipmentType.machinePlates.takesUnitFromInventory)
        #expect(EquipmentType.bodyweight.takesUnitFromInventory)
    }

    @Test("stackStepOffers in lbs is 5 and 10 lbs, never converted kg")
    func lbsStackStepsAreNotConvertedKg() {
        let offers = Rules.stackStepOffers(in: .lbs)
        #expect(offers == [
            Weight.lbs(hundredths: 500),
            Weight.lbs(hundredths: 1000),
        ])
        #expect(offers.allSatisfy { $0.unit == .lbs })
        #expect(!offers.contains { $0.decimalString == "2.3" || $0.decimalString == "4.5" })
    }

    @Test("stackStepOffers in kg is 5 and 10 kg")
    func kgStackSteps() {
        #expect(Rules.stackStepOffers(in: .kg) == [
            Weight.kg(hundredths: 500),
            Weight.kg(hundredths: 1000),
        ])
    }

    @Test("barIncrementOffers follow the unit, never a mix")
    func barIncrements() {
        #expect(Rules.barIncrementOffers(in: .kg) == [
            Weight.kg(hundredths: 125),
            Weight.kg(hundredths: 250),
            Weight.kg(hundredths: 500),
        ])
        #expect(Rules.barIncrementOffers(in: .lbs) == [
            Weight.lbs(hundredths: 250),
            Weight.lbs(hundredths: 500),
            Weight.lbs(hundredths: 1000),
        ])
    }

    @Test("exceptionNote only for an own unit that is not the rack")
    func theExceptionNote() {
        #expect(Rules.exceptionNote(tag: .locked(.kg), rack: .kg) == nil)
        #expect(Rules.exceptionNote(tag: .locked(.lbs), rack: .kg) == nil)
        #expect(Rules.exceptionNote(tag: .own(.kg), rack: .kg) == nil)
        #expect(
            Rules.exceptionNote(tag: .own(.lbs), rack: .kg)
                == "This machine is marked in LBS. Your gym is KG.")
        #expect(
            Rules.exceptionNote(tag: .own(.kg), rack: .lbs)
                == "This machine is marked in KG. Your gym is LBS.")
    }
}
