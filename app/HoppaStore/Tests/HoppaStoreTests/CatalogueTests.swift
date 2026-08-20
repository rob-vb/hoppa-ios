import Testing
@testable import HoppaStore

/// The Exercise Catalogue decides nothing, so what is checked is the two conventions
/// §6.3 states — and both are checkable against the list of strings alone, which is why
/// the spec chose them.
@Suite("The Exercise Catalogue")
struct CatalogueTests {

    @Test("About 150 names")
    func size() {
        #expect((120...180).contains(ExerciseCatalogue.names.count),
                "\(ExerciseCatalogue.names.count) names — §6.3 fixes the size at about 150")
    }

    @Test("No duplicate and no empty name")
    func namesAreDistinct() {
        var seen: Set<String> = []
        for name in ExerciseCatalogue.names {
            #expect(!name.isEmpty)
            #expect(name.trimmingWhitespace() == name, "\(name) has stray whitespace")
            #expect(seen.insert(name).inserted, "\(name) appears twice")
        }
    }

    /// **The prefix rule, mechanically.** As soon as a movement exists on more than one
    /// Equipment Type, every one of them carries a prefix — so a bare name must never
    /// also appear as the tail of a prefixed one. `Bench Press` bare beside
    /// `Barbell Bench Press` is exactly the mistake this catches.
    @Test("A bare name is never the tail of a prefixed one")
    func thePrefixRuleHolds() {
        let bare = Set(ExerciseCatalogue.names.filter { name in
            !ExerciseCatalogue.equipmentPrefixes.contains { name.hasPrefix($0 + " ") }
        })

        for name in ExerciseCatalogue.names {
            for prefix in ExerciseCatalogue.equipmentPrefixes where name.hasPrefix(prefix + " ") {
                let tail = String(name.dropFirst(prefix.count + 1))
                #expect(!bare.contains(tail), """
                    "\(tail)" is in the catalogue bare, and "\(name)" prefixes it. \
                    §6.3: once a movement exists on more than one Equipment Type, every \
                    one of them takes a prefix.
                    """)
                break   // longest prefix first, so `Smith Machine …` is never read as `Machine …`
            }
        }
    }

    @Test("The curated order puts a base movement above its own variants")
    func variantsFollowWhatTheyVary() {
        let index = Dictionary(
            uniqueKeysWithValues: ExerciseCatalogue.names.enumerated().map { ($1, $0) })

        for (position, name) in ExerciseCatalogue.names.enumerated() {
            // A variant is a name that extends another name in the list by trailing words.
            for other in ExerciseCatalogue.names
            where other != name && name.hasPrefix(other + " ") {
                #expect(index[other]! < position, """
                    "\(name)" is listed above "\(other)", which it varies. §6.3: the base \
                    movement comes first, which is what alphabetical order would not do.
                    """)
            }
        }
    }
}

private extension String {
    func trimmingWhitespace() -> String {
        var result = self[...]
        while let first = result.first, first == " " { result = result.dropFirst() }
        while let last = result.last, last == " " { result = result.dropLast() }
        return String(result)
    }
}
