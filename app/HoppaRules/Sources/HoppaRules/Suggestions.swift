/// The name field's ranked list (`SPEC.md` §6.3): the user's own names on top, the
/// shipped `ExerciseCatalogue` underneath, a name in both appearing once.
///
/// It is a rule and not a view helper: it decides an outcome from the `Logbook` alone,
/// and two lifters with the same `Logbook` see the same six rows.
///
/// **It imports nothing**, which is the whole reason this file exists rather than a home
/// in the store. `lowercased()` is standard library, Swift already compares `é` and
/// `e`+combining-acute as equal, and the base letter behind an accent is readable from
/// the Unicode character names the standard library ships — so accent folding costs about
/// ten lines and no `Foundation`.
///
/// > Decision record:
/// > [Name suggestions, and where a rule that needs Foundation lives](../../../../issues/0027-name-suggestions-and-foundation.md).

extension Rules {

    /// How many rows the field shows, on focus and while typing alike. A keyboard leaves
    /// room for about this many, and the reason the catalogue stops at ~150 names is that
    /// `press` must not return thirty rows — an uncapped typing list hands that failure
    /// straight back (`SPEC.md` §6.3).
    public static let suggestionLimit = 6

    /// The rows to show under the name field.
    ///
    /// An **empty** query is the on-focus case: the user's own names, most recently
    /// trained first, and **no catalogue entries mixed in** — on a first run it shows
    /// nothing and the user types.
    ///
    /// A **non-empty** query matches at the start of any word, case- and
    /// accent-insensitively, own names still first. `incline` finds both
    /// `Incline Dumbbell Press` and `Dumbbell Incline Press`; string-start matching fails
    /// exactly where it is needed, because a name often opens with the equipment.
    public static func nameSuggestions(in logbook: Logbook, query: String) -> [String] {
        let needle = fold(trimmed(query))
        var out: [String] = []
        var taken: Set<String> = []

        // Own names first. A name in both sources **keeps its own-names row**, because
        // that row carries the recency and the user wrote it.
        for name in ownNames(in: logbook) where needle.isEmpty || matches(name, needle) {
            guard taken.insert(fold(name)).inserted else { continue }
            out.append(name)
            if out.count == suggestionLimit { return out }
        }

        // On focus, before typing, the catalogue stays out of it.
        guard !needle.isEmpty else { return out }

        for name in ExerciseCatalogue.names where matches(name, needle) {
            guard taken.insert(fold(name)).inserted else { continue }
            out.append(name)
            if out.count == suggestionLimit { return out }
        }
        return out
    }

    /// The user's own names, derived live and never stored (`SPEC.md` §6.3).
    ///
    /// Read off the Exercises that exist **right now**, across **all** Programs — correct
    /// a typo and the wrong name is gone at once; delete an Exercise and its name goes
    /// with it. Sorted by the `startedAt` of the newest Workout that performed them,
    /// newest first, and **the Open Workout counts**: the Exercise logged ten minutes ago
    /// belongs at the top. A name on an Exercise that exists but was never trained sorts
    /// under the trained ones, in Program order.
    public static func ownNames(in logbook: Logbook) -> [String] {
        var trainedAt: [ExerciseID: Timestamp] = [:]
        for workout in logbook.workouts + (logbook.openWorkout.map { [$0] } ?? []) {
            for performed in workout.exercises {
                // Performed, not merely listed: a Skipped Exercise logged nothing, and a
                // Workout the user opened and walked away from trained nothing.
                guard !performed.sets.isEmpty else { continue }
                if workout.startedAt > trainedAt[performed.exerciseId] ?? -.infinity {
                    trainedAt[performed.exerciseId] = workout.startedAt
                }
            }
        }

        // Program order carries the never-trained ones, and breaks ties among the rest.
        let inOrder = logbook.allExercises
        let ranked = inOrder.enumerated().sorted { left, right in
            let a = trainedAt[left.element.id]
            let b = trainedAt[right.element.id]
            switch (a, b) {
            case (let a?, let b?): return a == b ? left.offset < right.offset : a > b
            case (.some, .none): return true
            case (.none, .some): return false
            case (.none, .none): return left.offset < right.offset
            }
        }

        var out: [String] = []
        var seen: Set<String> = []
        for exercise in ranked.map(\.element) where seen.insert(fold(exercise.name)).inserted {
            out.append(exercise.name)
        }
        return out
    }

    // MARK: - Matching

    /// Whether `needle` — already folded — starts a word of `name`.
    ///
    /// **A word breaks on a space or a hyphen, never on an apostrophe** (`SPEC.md` §6.3).
    /// `up` finds `Pull-up` and `Chin-up`, which are two words to a lifter; `Farmer's`
    /// stays one word, because `s` is not a search anyone makes.
    static func matches(_ name: String, _ needle: String) -> Bool {
        guard !needle.isEmpty else { return true }
        let folded = Array(fold(name))
        let wanted = Array(needle)
        guard folded.count >= wanted.count else { return false }

        var atWordStart = true
        for index in folded.indices {
            if atWordStart, folded[index...].starts(with: wanted) { return true }
            atWordStart = folded[index] == " " || folded[index] == "-"
        }
        return false
    }

    /// Lowercased, with an accent reduced to the letter under it.
    ///
    /// The base letter is read from the Unicode character name the standard library
    /// ships — `é` is `LATIN SMALL LETTER E WITH ACUTE` — and taken **only when it is a
    /// single letter `a`–`z`. So `ß` (`SHARP S`), `ı` (`DOTLESS I`), `æ` (`AE`) and `œ`
    /// (a `LIGATURE`, with no `LETTER` in its name at all) fall through unchanged rather
    /// than being guessed at. A combining mark is dropped, which is what makes the
    /// decomposed spelling of `é` fold to the same `e` as the precomposed one.
    ///
    /// > `fold("é") == "e"` is also the Mac's proof that Apple ships the Unicode name
    /// > tables — they are proved here on Linux. If that test goes red on the Mac, drop
    /// > folding and keep `lowercased()`.
    public static func fold(_ text: String) -> String {
        var out = String.UnicodeScalarView()
        for scalar in text.lowercased().unicodeScalars {
            if scalar.value >= 97 && scalar.value <= 122 {      // a–z, the common path
                out.append(scalar)
            } else if let base = baseLetter(of: scalar) {
                out.append(base)
            } else if !isCombiningMark(scalar) {
                out.append(scalar)
            }
        }
        return String(out)
    }

    /// The `a`–`z` letter an accented scalar is built on, or `nil` when there is not
    /// exactly one.
    static func baseLetter(of scalar: Unicode.Scalar) -> Unicode.Scalar? {
        guard let name = scalar.properties.name,
              let base = token(after: "LETTER", in: name),
              base.unicodeScalars.count == 1,
              let letter = base.unicodeScalars.first,
              letter.value >= 65, letter.value <= 90                 // A–Z
        else { return nil }
        return Unicode.Scalar(letter.value + 32)!                    // to a–z
    }

    static func isCombiningMark(_ scalar: Unicode.Scalar) -> Bool {
        scalar.properties.name?.hasPrefix("COMBINING ") ?? false
    }

    /// The word following `word` in a space-separated name, or `nil`.
    static func token(after word: String, in name: String) -> String? {
        var previous: Substring?
        for token in name.split(separator: " ") {
            if previous == word[...] { return String(token) }
            previous = token
        }
        return nil
    }

    /// Spaces off both ends. Without `Foundation` there is no `trimmingCharacters`, and
    /// this is the only trimming a rule here needs.
    static func trimmed(_ text: String) -> String {
        var slice = text[...]
        while let first = slice.first, first == " " || first == "\t" || first == "\n" {
            slice = slice.dropFirst()
        }
        while let last = slice.last, last == " " || last == "\t" || last == "\n" {
            slice = slice.dropLast()
        }
        return String(slice)
    }
}
