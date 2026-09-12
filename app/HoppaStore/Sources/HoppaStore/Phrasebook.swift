import Foundation
import HoppaRules

/// Every translatable word. Domain values stay mute; this book speaks them.
public struct Phrasebook: Sendable, Equatable {
    public let language: AppLanguage

    public init(_ language: AppLanguage) {
        self.language = language
    }

    public subscript(_ phrase: Phrase) -> String {
        switch language {
        case .english: english(phrase)
        case .dutch: dutch(phrase)
        }
    }

    public var locale: Locale { language.locale }

    public func step(_ n: Int) -> String {
        switch language {
        case .english: "Step \(n) of 3"
        case .dutch: "Stap \(n) van 3"
        }
    }

    public func screenName(_ mode: ProgressionMode) -> String {
        switch (language, mode) {
        case (.english, .progressiveOverload): "Progressive overload"
        case (.english, .microloading): "Microloading"
        case (.english, .none): "None"
        case (.dutch, .progressiveOverload): "Progressieve overload"
        case (.dutch, .microloading): "Microloading"
        case (.dutch, .none): "Geen"
        }
    }

    public func screenName(_ equipment: EquipmentType) -> String {
        switch (language, equipment) {
        case (.english, .barbell): "Barbell"
        case (.english, .dumbbell): "Dumbbell"
        case (.english, .machinePlates): "Machine (Plates)"
        case (.english, .machineStack): "Machine (Stack)"
        case (.english, .bodyweight): "Bodyweight"
        case (.dutch, .barbell): "Barbell"
        case (.dutch, .dumbbell): "Dumbbell"
        case (.dutch, .machinePlates): "Machine (schijven)"
        case (.dutch, .machineStack): "Machine (stack)"
        case (.dutch, .bodyweight): "Eigen gewicht"
        }
    }

    public func reason(_ block: DeleteBlock) -> String {
        switch (language, block) {
        case (.english, .openWorkoutRunsOnIt): "Finish your workout first."
        case (.english, .lastDayInProgram): "A program needs at least one workout day."
        case (.dutch, .openWorkoutRunsOnIt): "De workout loopt nog."
        case (.dutch, .lastDayInProgram): "Een programma heeft minstens één trainingsdag."
        }
    }

    public func reason(_ blocker: ProgressionBlocker) -> String {
        switch (language, blocker) {
        case (.english, .noWorkingWeight): "no weight yet"
        case (.english, .noIncrement): "no increment yet"
        case (.english, .noMicroplate): "no microplates · set up your rack"
        case (.english, .stranded): "microplate switched off · set up your rack"
        case (.english, .noStackStep): "no stack step yet"
        case (.dutch, .noWorkingWeight): "nog geen gewicht"
        case (.dutch, .noIncrement): "nog geen increment"
        case (.dutch, .noMicroplate): "geen microplates · zet je rek klaar"
        case (.dutch, .stranded): "microplate staat uit · zet je rek klaar"
        case (.dutch, .noStackStep): "nog geen stack step"
        }
    }

    public func exerciseCount(_ count: Int) -> String {
        switch (language, count) {
        case (.english, 0): "No exercises"
        case (.english, 1): "1 exercise"
        case (.english, _): "\(count) exercises"
        case (.dutch, 0): "Geen oefeningen"
        case (.dutch, 1): "1 oefening"
        case (.dutch, _): "\(count) oefeningen"
        }
    }

    public func dayCount(_ count: Int) -> String {
        switch (language, count) {
        case (.english, 1): "1 day"
        case (.english, _): "\(count) days"
        case (.dutch, 1): "1 dag"
        case (.dutch, _): "\(count) dagen"
        }
    }

    public func programSummary(days: Int, exercises: Int, unit: WeightUnit, mode: ProgressionMode) -> String {
        "\(dayCount(days)) · \(exerciseCount(exercises)) · \(unit.rawValue) · \(screenName(mode))"
    }

    public func rackName(isStandard: Bool, unit: WeightUnit) -> String {
        let kind = isStandard ? self[.standardRack] : self[.customRack]
        return "\(kind) \(unit.rawValue)"
    }

    public func relativeDay(_ elapsed: ElapsedDays) -> String {
        switch (language, elapsed) {
        case (.english, .never): "Never"
        case (.english, .today): "Today"
        case (.english, .yesterday): "Yesterday"
        case (.english, .daysAgo(let ago)): "\(ago.days) days ago"
        case (.dutch, .never): "Nooit"
        case (.dutch, .today): "Vandaag"
        case (.dutch, .yesterday): "Gisteren"
        case (.dutch, .daysAgo(let ago)): "\(ago.days) dagen geleden"
        }
    }

    public func exceptionNote(_ fact: UnitException) -> String {
        let own = fact.exerciseUnit.rawValue.uppercased()
        let rack = fact.rackUnit.rawValue.uppercased()
        switch language {
        case .english: return "This machine is marked in \(own). Your gym is \(rack)."
        case .dutch: return "Dit apparaat is ingesteld in \(own). Jouw gym is \(rack)."
        }
    }

    public func reweighHeadline(exerciseCount: Int) -> String {
        switch (language, exerciseCount) {
        case (.english, 1): "1 exercise has no weight"
        case (.english, _): "\(exerciseCount) exercises have no weight"
        case (.dutch, 1): "1 oefening heeft geen gewicht"
        case (.dutch, _): "\(exerciseCount) oefeningen hebben geen gewicht"
        }
    }

    public func reweighFootnote(exerciseCount: Int) -> String {
        switch (language, exerciseCount) {
        case (.english, 1): "It logs no set until you weigh it"
        case (.english, _): "They log no sets until you weigh them"
        case (.dutch, 1): "Die logt geen set tot je hem weegt"
        case (.dutch, _): "Die loggen geen sets tot je ze weegt"
        }
    }

    public func workoutCount(_ count: Int) -> String {
        switch (language, count) {
        case (.english, 1): "1 workout"
        case (.english, _): "\(count) workouts"
        case (.dutch, 1): "1 workout"
        case (.dutch, _): "\(count) workouts"
        }
    }

    public func wentUpCount(_ count: Int) -> String {
        switch (language, count) {
        case (.english, 1): "1 went up"
        case (.english, _): "\(count) went up"
        case (.dutch, 1): "1 ging omhoog"
        case (.dutch, _): "\(count) gingen omhoog"
        }
    }

    public func setCount(_ count: Int) -> String {
        switch (language, count) {
        case (.english, 1): "1 set"
        case (.english, _): "\(count) sets"
        case (.dutch, 1): "1 set"
        case (.dutch, _): "\(count) sets"
        }
    }

    public func skippedCount(_ count: Int) -> String {
        switch language {
        case .english: "\(count) skipped"
        case .dutch: "\(count) overgeslagen"
        }
    }

    public func sessionCount(_ count: Int) -> String {
        switch (language, count) {
        case (.english, 1): "1 session"
        case (.english, _): "\(count) sessions"
        case (.dutch, 1): "1 sessie"
        case (.dutch, _): "\(count) sessies"
        }
    }

    public func weekStreak(_ run: Int) -> String {
        switch (language, run) {
        case (.english, 1): "Week in a row"
        case (.english, _): "Weeks in a row"
        case (.dutch, 1): "Week op rij"
        case (.dutch, _): "Weken op rij"
        }
    }

    public func setsLogged(_ count: Int) -> String {
        switch (language, count) {
        case (.english, 1): "1 set logged"
        case (.english, _): "\(count) sets logged"
        case (.dutch, 1): "1 set gelogd"
        case (.dutch, _): "\(count) sets gelogd"
        }
    }

    public func stillOpen(_ count: Int) -> String {
        switch (language, count) {
        case (.english, 1): "1 exercise still open"
        case (.english, _): "\(count) exercises still open"
        case (.dutch, 1): "1 oefening staat nog open"
        case (.dutch, _): "\(count) oefeningen staan nog open"
        }
    }

    public func stillOpenHeading(_ name: String) -> String {
        switch language {
        case .english: "\(name) is still open"
        case .dutch: "\(name) staat nog open"
        }
    }

    public func youStartedNote(_ when: String) -> String {
        switch language {
        case .english: "You started it \(when). Hoppa never ends a workout by itself."
        case .dutch: "Je startte hem \(when). Hoppa beëindigt een workout nooit zelf."
        }
    }

    public func finishSkipNote(_ count: Int) -> String {
        switch language {
        case .english: "\(stillOpen(count)) · will be skipped"
        case .dutch: "\(stillOpen(count)) · \(count == 1 ? "wordt overgeslagen" : "worden overgeslagen")"
        }
    }

    public func skipAndFinishNote(open: Int) -> String {
        let skip = open == 1 ? self[.skipIt] : self[.skipThem]
        switch language {
        case .english: return "\(skip) and finish? \(self[.everyExerciseEndsCompleted])"
        case .dutch: return "\(skip) en afronden? \(self[.everyExerciseEndsCompleted])"
        }
    }

    public func nReps(_ reps: Int) -> String {
        switch language {
        case .english: "\(reps) reps"
        case .dutch: "\(reps) reps"
        }
    }

    public func putReps(_ reps: Int) -> String {
        switch language {
        case .english: "Put \(reps) reps"
        case .dutch: "Zet \(reps) reps"
        }
    }

    public func setOf(current: Int, total: Int) -> String {
        switch language {
        case .english: "set \(current) of \(total)"
        case .dutch: "set \(current) van \(total)"
        }
    }

    public func baseLabel(_ weight: Weight) -> String {
        switch language {
        case .english: "base \(weight.decimalString)"
        case .dutch: "basis \(weight.decimalString)"
        }
    }

    public func oneOffStays(_ weight: Weight) -> String {
        switch language {
        case .english:
            "one-off · \(weight.decimalString) \(weight.unit.rawValue) stays"
        case .dutch:
            "eenmalig · \(weight.decimalString) \(weight.unit.rawValue) blijft"
        }
    }

    public func noneStays(_ weight: Weight) -> String {
        switch language {
        case .english:
            "None · \(weight.decimalString) \(weight.unit.rawValue) stays"
        case .dutch:
            "Geen · \(weight.decimalString) \(weight.unit.rawValue) blijft"
        }
    }

    public func stays(_ weight: Weight) -> String {
        switch language {
        case .english: "stays \(weight.decimalString) \(weight.unit.rawValue)"
        case .dutch: "blijft \(weight.decimalString) \(weight.unit.rawValue)"
        }
    }

    public func ifAll(_ reps: Int) -> String {
        switch language {
        case .english: "if all \(reps)"
        case .dutch: "als alle \(reps)"
        }
    }

    public func downTo(_ weight: Weight) -> String {
        switch language {
        case .english: "Down to \(weight.decimalString) \(weight.unit.rawValue)"
        case .dutch: "Omlaag naar \(weight.decimalString) \(weight.unit.rawValue)"
        }
    }

    public func goTo(_ name: String) -> String {
        switch language {
        case .english: "Go to \(name)"
        case .dutch: "Naar \(name)"
        }
    }

    public func useTypedName(_ name: String) -> String {
        switch language {
        case .english: "Use “\(name)” as you typed it"
        case .dutch: "Gebruik “\(name)” zoals je hem typte"
        }
    }

    public func switchToUnit(_ unit: WeightUnit) -> String {
        switch language {
        case .english: "Switch to \(unit.rawValue.uppercased())"
        case .dutch: "Schakel naar \(unit.rawValue.uppercased())"
        }
    }

    public func thisClearsWeight(_ count: Int) -> String {
        switch (language, count) {
        case (.english, 1): "This clears the weight on 1 exercise"
        case (.english, _): "This clears the weight on \(count) exercises"
        case (.dutch, 1): "Dit wist het gewicht op 1 oefening"
        case (.dutch, _): "Dit wist het gewicht op \(count) oefeningen"
        }
    }

    public func stopsProgressing(_ count: Int) -> String {
        switch (language, count) {
        case (.english, 1):
            "It stops progressing until you pick another plate. Switch it back on and it progresses again."
        case (.english, _):
            "They stop progressing until you pick another plate. Switch them back on and they progress again."
        case (.dutch, 1):
            "Die stopt met progressie tot je een andere plaat kiest. Zet hem weer aan en hij gaat weer omhoog."
        case (.dutch, _):
            "Die stoppen met progressie tot je een andere plaat kiest. Zet ze weer aan en ze gaan weer omhoog."
        }
    }

    public func allSetsAt(sets: Int, reps: Int, to: String) -> String {
        switch language {
        case .english: "All \(sets) sets at \(reps) → \(to)"
        case .dutch: "Alle \(sets) sets op \(reps) → \(to)"
        }
    }

    public func allSetsBlocked(sets: Int, reps: Int, reason: String) -> String {
        switch language {
        case .english: "All \(sets) sets at \(reps) · \(reason)"
        case .dutch: "Alle \(sets) sets op \(reps) · \(reason)"
        }
    }

    public func deleteRemoves(exercises: String, sets: String) -> String {
        switch language {
        case .english: "This removes \(exercises) and \(sets) from your history."
        case .dutch: "Dit haalt \(exercises) en \(sets) uit je geschiedenis."
        }
    }

    public func youLoad(loaded: Weight, remainder: String) -> String {
        switch language {
        case .english:
            "you load \(loaded.decimalString) \(loaded.unit.rawValue) · \(remainder)"
        case .dutch:
            "je laadt \(loaded.decimalString) \(loaded.unit.rawValue) · \(remainder)"
        }
    }

    public func tapRowMeta(exerciseCount: Int) -> String {
        "\(self.exerciseCount(exerciseCount)) · \(self[.tapARowToOpenIt])"
    }

    public func plateOff(_ plate: Weight, rack: WeightUnit) -> String {
        switch language {
        case .english:
            "Your \(plate.decimalString) \(rack.rawValue) plate is switched off. Pick another, or switch it back on in your rack."
        case .dutch:
            "Je \(plate.decimalString) \(rack.rawValue)-plaat staat uit. Kies een andere, of zet hem weer aan in je rek."
        }
    }

    public func unitStashNote(showing unit: WeightUnit, held: WeightUnit?, numbersReturned: Bool) -> String? {
        var parts: [String] = []
        if numbersReturned {
            switch language {
            case .english:
                parts.append(
                    "The weight, the increment and the stack step you typed in \(unit.rawValue) are back.")
            case .dutch:
                parts.append(
                    "Het gewicht, het increment en de stack step die je in \(unit.rawValue) typte zijn terug.")
            }
        }
        if let held {
            switch language {
            case .english:
                parts.append(
                    "What you typed in \(held.rawValue) is kept under \(held.rawValue) — go back to \(held.rawValue) and it returns.")
            case .dutch:
                parts.append(
                    "Wat je in \(held.rawValue) typte blijft onder \(held.rawValue) — ga terug naar \(held.rawValue) en het keert terug.")
            }
        }
        guard !parts.isEmpty else { return nil }
        let head: String
        switch language {
        case .english: head = "The unit is now \(unit.rawValue)."
        case .dutch: head = "De eenheid is nu \(unit.rawValue)."
        }
        return ([head] + parts).joined(separator: " ")
    }

    public func oneOffStayed(_ weight: Weight) -> String {
        switch language {
        case .english: "One-off · \(weight.decimalString) \(weight.unit.rawValue) stayed"
        case .dutch: "Eenmalig · \(weight.decimalString) \(weight.unit.rawValue) bleef"
        }
    }

    public func chartFor(_ name: String, day: String) -> String {
        switch language {
        case .english: "Chart for \(name), \(day)"
        case .dutch: "Grafiek voor \(name), \(day)"
        }
    }

    public func onDate(_ date: String) -> String {
        switch language {
        case .english: "On \(date)"
        case .dutch: "Op \(date)"
        }
    }

    public func logReps(_ reps: Int) -> String {
        switch language {
        case .english: "Log \(reps) reps"
        case .dutch: "Log \(reps) reps"
        }
    }

    public func targetReps(_ reps: Int) -> String {
        switch language {
        case .english: "Target \(reps) reps"
        case .dutch: "Doel \(reps) reps"
        }
    }

    public func nextExercise(_ name: String) -> String {
        switch language {
        case .english: "Next: \(name)"
        case .dutch: "Volgende: \(name)"
        }
    }

    public var monthAbbreviations: [String] {
        switch language {
        case .english:
            ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"]
        case .dutch:
            ["JAN", "FEB", "MRT", "APR", "MEI", "JUN", "JUL", "AUG", "SEP", "OKT", "NOV", "DEC"]
        }
    }

    public func exerciseAt(day: String, position: Int) -> String {
        switch language {
        case .english: "\(day) · Exercise \(position)"
        case .dutch: "\(day) · Oefening \(position)"
        }
    }

    public func plusPlate(_ plate: Weight) -> String {
        "+\(plate.decimalString) \(plate.unit.rawValue) \(self[.plateNoun])"
    }

    public func stepBy(_ step: Weight) -> String {
        switch language {
        case .english: "− / + step by \(step.decimalString) \(step.unit.rawValue)"
        case .dutch: "− / + stap van \(step.decimalString) \(step.unit.rawValue)"
        }
    }

    public func perSideTotal(_ load: BarLoad) -> String {
        let perSide: String
        switch language {
        case .english:
            perSide = "\(load.perSide.decimalString) \(load.perSide.unit.rawValue) per side"
        case .dutch:
            perSide = "\(load.perSide.decimalString) \(load.perSide.unit.rawValue) per kant"
        }
        guard load.printsBaseWeight else { return perSide }
        switch language {
        case .english: return "\(load.baseWeight.decimalString) base + \(perSide)"
        case .dutch: return "\(load.baseWeight.decimalString) basis + \(perSide)"
        }
    }

    public func beltLine(added: Weight, plateCount: Int) -> String {
        let unit = added.unit.rawValue
        let belt = self[.onTheBelt]
        if plateCount == 1 {
            return "1 × \(added.decimalString) \(unit) \(belt)"
        }
        return "\(added.decimalString) \(unit) \(belt)"
    }

    public func gapRemainder(size: Weight, over: Bool) -> String {
        "\(size.decimalString) \(over ? self[.over] : self[.under])"
    }

    public func reweighProgress(done: Int, total: Int, left: Int) -> String {
        switch language {
        case .english:
            "\(done) of \(total) done. \(left) still \(left == 1 ? "has" : "have") no weight."
        case .dutch:
            "\(done) van \(total) gedaan. \(left) \(left == 1 ? "heeft" : "hebben") nog geen gewicht."
        }
    }

    public func exercisesPerformed(_ count: Int) -> String {
        switch (language, count) {
        case (_, 0): self[.noExercisesPerformed]
        case (.english, 1): "1 Exercise performed. Every Set is logged."
        case (.english, _): "\(count) Exercises performed. Every Set is logged."
        case (.dutch, 1): "1 oefening uitgevoerd. Elke set is gelogd."
        case (.dutch, _): "\(count) oefeningen uitgevoerd. Elke set is gelogd."
        }
    }

    public func stillRunning(_ name: String) -> String {
        switch language {
        case .english: "\(name) is still running"
        case .dutch: "\(name) loopt nog"
        }
    }

    public func setsDone(logged: Int, planned: Int) -> String {
        switch language {
        case .english: "\(logged) of \(planned) sets done"
        case .dutch: "\(logged) van \(planned) sets gedaan"
        }
    }

    public func openShort(_ count: Int) -> String {
        "\(count) \(self[.openLabel])"
    }

    public func usesThisPlate(_ count: Int) -> String {
        switch (language, count) {
        case (.english, 1): "1 exercise uses this plate"
        case (.english, _): "\(count) exercises use this plate"
        case (.dutch, 1): "1 oefening gebruikt deze plaat"
        case (.dutch, _): "\(count) oefeningen gebruiken deze plaat"
        }
    }

    public func doneEarlyNote(logged: Int, planned: Int) -> String {
        switch language {
        case .english: "\(logged) of \(planned) sets · \(self[.willNotProgress])"
        case .dutch: "\(logged) van \(planned) sets · \(self[.willNotProgress])"
        }
    }

    public func microloadingHang(
        plate: Weight, rack: WeightUnit, step: Weight, workingUnit: WeightUnit
    ) -> String {
        switch language {
        case .english:
            "\(plate.decimalString) \(rack.rawValue) hangs on the pin, and rolls into the stack at \(step.decimalString) \(workingUnit.rawValue)."
        case .dutch:
            "\(plate.decimalString) \(rack.rawValue) hangt aan de pin, en rolt in de stack bij \(step.decimalString) \(workingUnit.rawValue)."
        }
    }

    public func plusOnTheBar(_ jump: Weight) -> String {
        switch language {
        case .english: "+\(jump.decimalString) \(jump.unit.rawValue) on the bar."
        case .dutch: "+\(jump.decimalString) \(jump.unit.rawValue) op de stang."
        }
    }

    public func plusPerProgression(_ jump: Weight) -> String {
        switch language {
        case .english: "+\(jump.decimalString) \(jump.unit.rawValue) per progression."
        case .dutch: "+\(jump.decimalString) \(jump.unit.rawValue) per progressie."
        }
    }

    public func mixedUnitUnmoved() -> String {
        switch language {
        case .english:
            "The line is the microload. The pin has not moved, so the pin is not on it. Nothing here converts."
        case .dutch:
            "De lijn is de microload. De pin is niet bewogen, dus de pin staat er niet op. Hier wordt niets omgerekend."
        }
    }

    public func mixedUnitMoved(from: Weight, to: Weight) -> String {
        switch language {
        case .english:
            "The line is the microload. The pin has gone from \(from.decimalString) \(from.unit.rawValue) to \(to.decimalString) \(to.unit.rawValue), and the line drops back each time the microload rolls onto it. Nothing here converts."
        case .dutch:
            "De lijn is de microload. De pin ging van \(from.decimalString) \(from.unit.rawValue) naar \(to.decimalString) \(to.unit.rawValue), en de lijn zakt terug elke keer dat de microload erop rolt. Hier wordt niets omgerekend."
        }
    }

    public func stateName(_ state: ExerciseState) -> String {
        switch state {
        case .open: self[.stateOpen]
        case .completed: self[.stateCompleted]
        case .skipped: self[.skipped]
        }
    }

    public func volumeLabel(_ unit: WeightUnit) -> String {
        "\(unit.rawValue) \(self[.volumeSuffix])"
    }

    public func ifAllIncrement(_ increment: Weight, reps: Int) -> String {
        "+\(increment.decimalString) \(increment.unit.rawValue) \(ifAll(reps))"
    }

    public func nextTimeWeight(_ weight: Weight) -> String {
        "→ \(weight.decimalString) \(weight.unit.rawValue) \(self[.nextTime])"
    }

    public func nextTimeMixed(working: Weight, micro: Weight) -> String {
        "→ \(working.decimalString) \(working.unit.rawValue) +\(micro.decimalString) \(micro.unit.rawValue) \(self[.nextTime])"
    }

    public func setAt(_ reps: Int) -> String {
        "\(self[.setAtLabel]) \(reps)"
    }

    public func ticketLine(_ ticket: String) -> String {
        "\(self[.ticket]) \(ticket)"
    }

    public func loadLine(_ load: StackLoad) -> String {
        var line = "\(pinAt) \(columnPhrase(load))"
        let hanging = hangingLabels(load)
        if !hanging.isEmpty { line += " · " + hanging.joined(separator: " + ") }
        return line
    }

    public func qualifierLine(_ load: StackLoad) -> String {
        var line = columnPhrase(load)
        for plate in load.pinRemainder { line += " + \(spokenNumber(plate, load: load))" }
        if let micro = load.microload, !micro.isZero {
            line += " + \(named(micro, load: load))"
        }
        return line
    }

    private var pinAt: String {
        switch language {
        case .english: "pin at"
        case .dutch: "pin op"
        }
    }

    private func columnPhrase(_ load: StackLoad) -> String {
        "\(load.columnMass.decimalString) \(load.columnMass.unit.rawValue)"
    }

    private func hangingLabels(_ load: StackLoad) -> [String] {
        var labels = load.pinRemainder.map { named($0, load: load) }
        if !load.microloadPlates.isEmpty {
            labels += load.microloadPlates.map { named($0, load: load) }
        } else if let micro = load.microload, !micro.isZero {
            labels.append(named(micro, load: load))
        }
        return labels
    }

    private func spokenNumber(_ plate: Weight, load: StackLoad) -> String {
        if load.workingUnit == .kg, plate.unit == .lbs,
           let sticker = Sticker(of: plate, readIn: .kg) {
            return sticker.decimalString
        }
        return plate.decimalString
    }

    private func named(_ plate: Weight, load: StackLoad) -> String {
        if load.workingUnit == .kg, plate.unit == .lbs,
           let sticker = Sticker(of: plate, readIn: .kg) {
            return "\(sticker.decimalString) kg"
        }
        return "\(plate.decimalString) \(plate.unit.rawValue)"
    }
}
