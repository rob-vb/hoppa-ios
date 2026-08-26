import Testing
import HoppaRules

/// The name field (`SPEC.md` §6.3): two sources, one ranked list, six rows.
///
/// The rule lives in `HoppaRules` because it decides an outcome from the `Logbook` alone.
/// It was once recorded as needing `Foundation` to fold accents; nobody had compiled the
/// claim, and it was wrong three ways over.
///
/// > Decision record:
/// > [Name suggestions, and where a rule that needs Foundation lives](../../../../issues/0027-name-suggestions-and-foundation.md).
@Suite("SPEC.md §6.3 — the name field")
struct SuggestionTests {

    /// A Program whose Exercise names are unmistakable, plus history to rank them by.
    static func book() -> Logbook {
        Logbook(
            nextId: 100,
            plateInventory: rackKg(),
            programs: [
                Program(
                    id: Ids.program, name: "Upper / Lower",
                    defaultWeightUnit: .kg, mode: .progressiveOverload,
                    days: [WorkoutDay(id: Ids.upperA, name: "Upper A", exercises: [
                        exercise(1, "Incline Dumbbell Press"),
                        exercise(2, "Dumbbell Incline Press"),
                        exercise(3, "Pull-up"),
                        exercise(4, "Farmer's Walk"),
                        exercise(5, "Barbell Bench Press")
                    ])])
            ])
    }

    static func exercise(_ id: Int, _ name: String) -> Exercise {
        Exercise(
            id: ExerciseID(id), name: name, equipment: .barbell,
            plannedSets: 1, repRange: RepRange(8, 12),
            workingWeight: kg("60"), increment: kg("2.5"))
    }

    // MARK: - Folding (§6.3, and the Mac's own check)

    @Test("An accent folds to the letter under it, in either spelling")
    func accentsFold() {
        for (accented, plain) in [
            ("é", "e"), ("è", "e"), ("ê", "e"), ("ë", "e"),
            ("á", "a"), ("à", "a"), ("â", "a"), ("ä", "a"), ("å", "a"),
            ("ø", "o"), ("ç", "c"), ("ñ", "n"), ("ü", "u"), ("İ", "i")
        ] {
            #expect(Rules.fold(accented) == plain, "\(accented) folded wrong")
        }
        // The decomposed spelling folds to the same letter as the precomposed one.
        #expect(Rules.fold("e\u{0301}") == "e")
        #expect(Rules.fold("Café Press") == "cafe press")
    }

    /// The guard that stops the fold guessing. `ß` is `SHARP S`, `ı` is `DOTLESS I` and
    /// `œ` is a `LIGATURE` with no `LETTER` in its name at all — none of them is one
    /// letter with a mark on it, so none of them is folded.
    @Test("A letter that is not one letter with a mark stays exactly as it is")
    func onlySingleBaseLettersFold() {
        #expect(Rules.fold("ß") == "ß")
        #expect(Rules.fold("ı") == "ı")
        #expect(Rules.fold("œ") == "œ")
        #expect(Rules.fold("æ") == "æ")
        #expect(Rules.fold("Smith incline 30°") == "smith incline 30°")
    }

    // MARK: - Matching (§6.3)

    @Test("Matching starts at any word, not only at the string")
    func matchingStartsAtAnyWord() {
        let names = Rules.nameSuggestions(in: Self.book(), query: "incline")
        #expect(names.contains("Incline Dumbbell Press"))
        #expect(names.contains("Dumbbell Incline Press"))
    }

    @Test("A word breaks on a hyphen, and never on an apostrophe")
    func whatCountsAsAWord() {
        #expect(Rules.nameSuggestions(in: Self.book(), query: "up").contains("Pull-up"))
        // `s` is not a search anyone makes, so `Farmer's` stays one word.
        #expect(!Rules.nameSuggestions(in: Self.book(), query: "s").contains("Farmer's Walk"))
        #expect(Rules.nameSuggestions(in: Self.book(), query: "farmer").contains("Farmer's Walk"))
    }

    @Test("Matching is case- and accent-insensitive, and a query is trimmed")
    func matchingIgnoresCaseAndAccents() {
        #expect(Rules.nameSuggestions(in: Self.book(), query: "PULL").contains("Pull-up"))
        #expect(Rules.nameSuggestions(in: Self.book(), query: "  pull ").contains("Pull-up"))
    }

    @Test("A query in the middle of a word matches nothing")
    func noSubstringMatching() {
        #expect(Rules.nameSuggestions(in: Self.book(), query: "cline").isEmpty)
    }

    // MARK: - Ranking (§6.3)

    @Test("On focus the list is the user's own names, and no catalogue entry is mixed in")
    func onFocusOwnNamesOnly() {
        let names = Rules.nameSuggestions(in: Self.book(), query: "")
        #expect(names.count == 5)
        #expect(!names.contains("Barbell Bench Press Close Grip"))      // catalogue, not his
    }

    @Test("On a first run the field shows nothing and the user types")
    func aFirstRunShowsNothing() {
        #expect(Rules.nameSuggestions(in: .empty, query: "").isEmpty)
    }

    @Test("Most recently used means most recently trained, and the Open Workout counts")
    func recencyIsTrainingAndNotPosition() {
        var session = Session(Self.book())
        session.start()
        session.goTo(ExerciseID(3))                                     // Pull-up
        session.logSets(1, reps: 10)
        session.send(.skipRemainingAndFinish)

        session.start()
        session.goTo(ExerciseID(5))                                     // Barbell Bench Press
        session.logSets(1, reps: 10)                                    // still Open

        let names = Rules.nameSuggestions(in: session.book, query: "")
        #expect(names.first == "Barbell Bench Press")                   // ten minutes ago
        #expect(names[1] == "Pull-up")
        // The never-trained ones sort under them, in Program order.
        #expect(names[2] == "Incline Dumbbell Press")
    }

    @Test("A name leaves the suggestions with the Exercise that carried it")
    func ownNamesAreDerivedLive() {
        var session = Session(Self.book())
        session.send(.deleteExercise(ExerciseID(3)))

        #expect(!Rules.nameSuggestions(in: session.book, query: "").contains("Pull-up"))
        // Correct a typo and the wrong name is gone at once — one save, no cleanup screen.
        var draft = ExerciseDraft(
            session.book.exercise(ExerciseID(4))!, in: session.book.plateInventory)
        draft.name = "Farmers Walk"
        session.send(.saveExercise(ExerciseID(4), draft: draft))
        let names = Rules.nameSuggestions(in: session.book, query: "")
        #expect(names.contains("Farmers Walk"))
        #expect(!names.contains("Farmer's Walk"))
    }

    // MARK: - The two sources, and the cap

    @Test("Own names come first, and the catalogue follows underneath")
    func ownNamesOutrankTheCatalogue() {
        let names = Rules.nameSuggestions(in: Self.book(), query: "barbell bench")
        #expect(names.first == "Barbell Bench Press")
        #expect(names.dropFirst().contains("Barbell Bench Press Close Grip"))
    }

    @Test("A name in both sources keeps its own-names row, and appears once")
    func aDuplicateKeepsItsOwnRow() {
        var book = Self.book()
        // The user's own row is the one that carries the recency, whatever its spelling.
        book.programs[0].days[0].exercises[4].name = "barbell bench press"
        let names = Rules.nameSuggestions(in: book, query: "barbell bench press")

        #expect(names.first == "barbell bench press")
        #expect(names.filter { Rules.fold($0) == "barbell bench press" }.count == 1)
    }

    @Test("Six rows at most, on focus and while typing alike")
    func sixRowsAtMost() {
        var book = Self.book()
        for index in 0..<10 {
            book.programs[0].days[0].exercises.append(
                Self.exercise(50 + index, "Machine Press \(index)"))
        }
        #expect(Rules.nameSuggestions(in: book, query: "").count == 6)
        #expect(Rules.nameSuggestions(in: book, query: "press").count == 6)
        // The cap is the reason the catalogue stops at ~150 names: `press` must not
        // return thirty rows.
        #expect(Rules.nameSuggestions(in: .empty, query: "press").count == 6)
    }

    @Test("A suggestion is a name and nothing else")
    func aSuggestionSetsOnlyTheName() {
        // There is nothing else to set: the list is `[String]`, and the catalogue stores
        // no Equipment Type to infer one from.
        #expect(ExerciseCatalogue.names.contains("Barbell Bench Press"))
    }
}
