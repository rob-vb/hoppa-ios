// Ticket 0043 — the Exercise sheet's unit stash, walked on this machine.
//
// `UnitStash.swift` is the **real file**, compiled in beside this one — every decision
// about what is filed, what comes back and what the note says is proved here and not in a
// copy. `Sheet` below is the thin ring around it that `ExerciseSheet` also draws: the
// derived `unit`, `clearForUnitChange`, `show`, `weight` and `hasContent`, with `@State`
// and the SwiftUI wrapper dropped. **That ring is a copy and it can rot**; keep it in step
// by hand when the sheet changes, and keep it as small as it is.
//
// The save goes through `Rules.reduce`, the door `LogbookStore.send` uses, so a draft is
// judged by the shipping rule.
//
// Run it with `./run.sh`.
import Foundation
import HoppaRules

final class Sheet {
    var draft: ExerciseDraft
    var equipmentChosen: Bool
    let rack: PlateInventory

    var workingText = ""
    var incrementText = ""
    var stackText = ""
    var incrementTyped = false
    var stackTyped = false

    var stash = UnitStash()

    init(draft: ExerciseDraft, equipmentChosen: Bool, rack: PlateInventory) {
        self.draft = draft
        self.equipmentChosen = equipmentChosen
        self.rack = rack
        self.workingText = draft.workingWeight?.decimalString ?? ""
        self.incrementText = draft.increment?.decimalString ?? ""
        self.stackText = draft.stackStep?.decimalString ?? ""
    }

    var unitTag: UnitTag {
        Rules.unitTag(
            equipment: equipmentChosen ? draft.equipment : nil,
            own: draft.ownWeightUnit,
            rack: rack.unit)
    }

    var unit: WeightUnit { unitTag.unit }

    // --- verbatim from ExerciseSheet ---
    func clearForUnitChange() {
        let leaving = draft.shownUnit
        draft.shownUnit = unit
        guard leaving != unit else { return }
        show(stash.move(
            from: leaving, to: unit,
            onScreen: TypedWeights(
                working: workingText, increment: incrementText, stack: stackText,
                incrementTyped: incrementTyped, stackTyped: stackTyped)))
    }

    func show(_ typed: TypedWeights) {
        workingText = typed.working
        incrementText = typed.increment
        stackText = typed.stack
        incrementTyped = typed.incrementTyped
        stackTyped = typed.stackTyped
        draft.workingWeight = weight(typed.working)
        draft.increment = weight(typed.increment)
        draft.stackStep = weight(typed.stack)
    }

    func weight(_ text: String) -> Weight? {
        text.isEmpty ? nil : Weight(decimalString: text, unit: unit)
    }

    var unitMoveNote: String? { stash.note(showing: unit) }

    var hasContent: Bool {
        !draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || equipmentChosen || !workingText.isEmpty || !incrementText.isEmpty
            || !stackText.isEmpty
            || stash.hasNumbers
    }
    // --- end verbatim ---

    /// The keystroke path: type into the Working Weight box.
    func typeWorking(_ text: String) {
        stash.forget()
        workingText = text
        draft.workingWeight = weight(text)
    }

    func flipUnit() {
        draft.ownWeightUnit = unit == .kg ? .lbs : .kg
        clearForUnitChange()
    }

    func pick(_ type: EquipmentType) {
        equipmentChosen = true
        draft.equipment = type
        clearForUnitChange()
    }

    /// What the save writes, through the **real** door — `Rules.reduce`, the one
    /// `LogbookStore.send` uses — so the draft is judged by the shipping rule and not by
    /// a copy of it.
    func saved() -> Exercise {
        var book = Logbook(plateInventory: rack)
        book = Rules.reduce(book, .createProgram(name: "P", defaultWeightUnit: draft.ownWeightUnit, mode: .progressiveOverload), at: 0)
        let program = book.programs[0]
        book = Rules.reduce(book, .addWorkoutDay(programId: program.id, name: "Upper A"), at: 0)
        let day = book.programs[0].days[0]
        var out = draft
        out.name = out.name.isEmpty ? "X" : out.name
        book = Rules.reduce(book, .addExercise(workoutDayId: day.id, at: 0, draft: out), at: 0)
        return book.programs[0].days[0].exercises[0]
    }
}

nonisolated(unsafe) extension UnitStash {
    /// What is filed under a unit. The drawer is `private` on purpose, so this asks the
    /// only question the type answers — *move to this unit and hand back what was there* —
    /// on a **copy**, and reads the answer off the return value.
    func filedWorking(_ unit: WeightUnit) -> String? {
        var probe = self
        let out = probe.move(from: unit == .kg ? .lbs : .kg, to: unit, onScreen: TypedWeights())
        return out.isEmpty ? nil : out.working
    }
}

nonisolated(unsafe) var failures = 0
func check(_ what: String, _ ok: Bool) {
    print((ok ? "ok   " : "FAIL ") + what)
    if !ok { failures += 1 }
}

let kgRack = PlateInventory.standard(.kg)

func editDraft() -> ExerciseDraft {
    ExerciseDraft(
        name: "Cable Row",
        equipment: .machineStack,
        ownWeightUnit: .kg,
        plannedSets: 3,
        repRange: RepRange(8, 12),
        workingWeight: Weight(decimalString: "60", unit: .kg),
        increment: Weight(decimalString: "2.5", unit: .kg),
        stackStep: Weight(decimalString: "5", unit: .kg),
        shownUnit: .kg)
}

print("— the mis-tap, and the tap back —")
do {
    let s = Sheet(draft: editDraft(), equipmentChosen: true, rack: kgRack)
    s.flipUnit()
    check("the flip empties the screen", s.workingText.isEmpty && s.incrementText.isEmpty && s.stackText.isEmpty)
    check("the flip holds the three numbers", s.stash.filedWorking(.kg) == "60")
    check("the note says kept, not cleared", s.unitMoveNote?.contains("is kept under kg") == true)
    check("the note does not say cleared", s.unitMoveNote?.contains("cleared") == false)
    s.flipUnit()
    check("the tap back returns the weight", s.workingText == "60")
    check("the tap back returns the increment", s.incrementText == "2.5")
    check("the tap back returns the stack step", s.stackText == "5")
    check("the note says they are back", s.unitMoveNote?.contains("are back") == true)
    check("the stash is empty again", !s.stash.hasNumbers)
    let e = s.saved()
    check("the save writes the weight it opened with", e.workingWeight == Weight(decimalString: "60", unit: .kg))
    check("the save writes the stack step", e.storedStackStep == Weight(decimalString: "5", unit: .kg))
}

print("— a number typed after the flip, and a flip back —")
do {
    let s = Sheet(draft: editDraft(), equipmentChosen: true, rack: kgRack)
    s.flipUnit()
    s.typeWorking("135")
    check("the note ends at the first keystroke", s.unitMoveNote == nil)
    s.flipUnit()
    check("the kg number is back on screen", s.workingText == "60")
    check("the lbs number is held", s.stash.filedWorking(.lbs) == "135")
    check("both halves are in the note", s.unitMoveNote?.contains("are back") == true && s.unitMoveNote?.contains("is kept under lbs") == true)
    s.flipUnit()
    check("the lbs number comes back", s.workingText == "135")
    check("its label is LBS", s.draft.workingWeight == Weight(decimalString: "135", unit: .lbs))
    let e = s.saved()
    check("the save writes the lbs number", e.workingWeight == Weight(decimalString: "135", unit: .lbs))
}

print("— a restored number cleared by hand stays gone —")
do {
    let s = Sheet(draft: editDraft(), equipmentChosen: true, rack: kgRack)
    s.flipUnit()
    s.typeWorking("135")
    s.typeWorking("")
    s.flipUnit()
    check("nothing is held under LBS", s.stash.filedWorking(.lbs) == nil)
    check("the kg numbers still return", s.workingText == "60")
    s.flipUnit()
    check("the emptied LBS screen stays empty", s.workingText.isEmpty)
    check("and nothing claims to be back", s.stash.numbersReturned == false)
}

print("— the add sheet's one free flip —")
do {
    // A Program whose default is LBS on a KG rack: the sheet draws LBS before a chip is
    // picked, and the first pick moves it to KG.
    var d = ExerciseDraft(
        name: "", equipment: .barbell, ownWeightUnit: .lbs, plannedSets: 3,
        repRange: RepRange(8, 12), shownUnit: .lbs)
    d.name = "Bench Press"
    let s = Sheet(draft: d, equipmentChosen: false, rack: kgRack)
    check("the sheet opens on the program default", s.unit == .lbs)
    check("and the draft agrees", s.draft.shownUnit == .lbs)
    s.typeWorking("100")
    s.pick(.dumbbell)
    check("a dumbbell in LBS keeps the typed number", s.workingText == "100")
    check("and the save keeps it too", s.saved().workingWeight == Weight(decimalString: "100", unit: .lbs))
}
do {
    var d = ExerciseDraft(
        name: "", equipment: .barbell, ownWeightUnit: .lbs, plannedSets: 3,
        repRange: RepRange(8, 12), shownUnit: .lbs)
    d.name = "Bench Press"
    let s = Sheet(draft: d, equipmentChosen: false, rack: kgRack)
    s.typeWorking("100")
    s.pick(.barbell)
    check("a barbell moves to the rack's unit", s.unit == .kg)
    check("the LBS number leaves the screen", s.workingText.isEmpty)
    check("and it is held, not destroyed", s.stash.filedWorking(.lbs) == "100")
    check("the X would ask before it goes", s.hasContent)
    s.typeWorking("60")
    check("the save writes the KG number", s.saved().workingWeight == Weight(decimalString: "60", unit: .kg))
}
do {
    let s = Sheet(
        draft: ExerciseDraft(
            name: "Squat", equipment: .barbell, ownWeightUnit: .kg, plannedSets: 3,
            repRange: RepRange(8, 12), shownUnit: .kg),
        equipmentChosen: false, rack: kgRack)
    s.pick(.machineStack)
    check("an empty add sheet holds nothing", !s.stash.hasNumbers)
    check("and says nothing", s.unitMoveNote == nil)
    s.typeWorking("40")
    check("the first number on a fresh sheet survives the save", s.saved().workingWeight == Weight(decimalString: "40", unit: .kg))
}

print("— a custom stack step survives a flip —")
do {
    let s = Sheet(draft: editDraft(), equipmentChosen: true, rack: kgRack)
    s.stackTyped = true
    s.stackText = "7.5"
    s.draft.stackStep = s.weight("7.5")
    s.flipUnit()
    check("the flip empties the stack field", s.stackText.isEmpty)
    check("and closes the … field", !s.stackTyped)
    s.flipUnit()
    check("the custom step is back", s.stackText == "7.5")
    check("the … field is still open", s.stackTyped)
    let e = s.saved()
    check("the save writes the custom step", e.storedStackStep == Weight(decimalString: "7.5", unit: .kg))
}

print(failures == 0 ? "\nall green" : "\n\(failures) FAILED")
// A red check exits 1, so a runner never reads a failure as a pass.
exit(failures == 0 ? 0 : 1)
