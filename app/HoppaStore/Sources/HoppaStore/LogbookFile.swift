import Foundation
import HoppaRules

/// Everything that turns bytes into a `Logbook` and back — with no file in sight.
///
/// Encode, decode and migrate are **pure static functions** on purpose: they are the part
/// of the store worth testing hardest, and a test of them needs no temporary directory.
/// `LogbookStore` owns the URL; this owns the format.
public enum LogbookFile {

    // MARK: - Encoding

    /// Stable JSON: sorted keys, no escaped slashes. The same encoder `HoppaRules` records
    /// its fixtures with, so a file written here and a fixture committed there are the
    /// same bytes for the same value.
    ///
    /// Pretty-printed, which roughly doubles the file. Ticket 19 measured five years of
    /// training at a few hundred kilobytes; doubling that is still nothing next to being
    /// able to read Rob's logbook in a text editor when something goes wrong on his phone.
    public static var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted, .withoutEscapingSlashes]
        return encoder
    }

    public static func encode(_ logbook: Logbook) throws -> Data {
        try encoder.encode(logbook)
    }

    // MARK: - Decoding

    /// Reads `schemaVersion` without decoding the rest, so a file this build must refuse
    /// is refused before its unknown fields are ever looked at.
    public static func version(in data: Data) throws -> Int {
        guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw LogbookFileError.notJSON
        }
        guard let version = object["schemaVersion"] as? Int else {
            throw LogbookFileError.noSchemaVersion
        }
        return version
    }

    /// Bytes to `Logbook`, migrating on the way up if the file is older than this build.
    ///
    /// A file from a **newer** build is refused rather than parsed. `JSONDecoder` would
    /// happily drop the fields it does not know, and the next save would write that loss
    /// back permanently — with a backup taken from the same moment, which does not help.
    public static func decode(_ data: Data) throws -> Logbook {
        let found = try version(in: data)
        guard found <= Logbook.currentSchemaVersion else {
            throw LogbookFileError.fromNewerBuild(found: found, known: Logbook.currentSchemaVersion)
        }

        let current = try migrate(data, from: found)
        do {
            return try JSONDecoder().decode(Logbook.self, from: current)
        } catch {
            throw LogbookFileError.malformed(String(describing: error))
        }
    }

    // MARK: - Migration

    /// One numbered step, working on decoded JSON.
    ///
    /// JSON and not a frozen `LogbookV1` struct: freezing the model per version copies
    /// twenty-odd files of value types on every bump. It is type-safe and unaffordable.
    public typealias Step = @Sendable (inout [String: Any]) throws -> Void

    /// Keyed by the version a step migrates **from**: `steps[2]` takes a v2 file to v3.
    ///
    /// **Empty, and that is not a gap.** Migration is additive by default — see
    /// `Logbook.currentSchemaVersion`'s note — so a step exists only for a destructive
    /// change. There has not been one. The engine below is tested with a step table a
    /// test supplies, because machinery that first runs on Rob's phone is machinery that
    /// has never run.
    public static let steps: [Int: Step] = [:]

    public static func migrate(_ data: Data, from version: Int) throws -> Data {
        try migrate(data, from: version, to: Logbook.currentSchemaVersion, steps: steps)
    }

    public static func migrate(
        _ data: Data, from version: Int, to target: Int, steps: [Int: Step]
    ) throws -> Data {
        guard version < target else { return data }
        guard var object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw LogbookFileError.notJSON
        }
        for from in version..<target {
            guard let step = steps[from] else {
                throw LogbookFileError.noMigrationPath(from: from)
            }
            try step(&object)
            // The step never has to remember to stamp the version. Forgetting it would
            // leave a migrated file claiming to be old, and migrate it again next launch.
            object["schemaVersion"] = from + 1
        }
        return try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
    }
}

/// Why a file could not become a `Logbook`. Every case ends as `.unreadable`, and the
/// case is what a support answer to Rob is built from.
public enum LogbookFileError: Error, Sendable, Hashable {
    /// Not JSON at all, or JSON that is not an object.
    case notJSON
    /// JSON, but with no `schemaVersion` — so it is not a Logbook.
    case noSchemaVersion
    /// Written by a newer build of Hoppa. Refused, never parsed.
    case fromNewerBuild(found: Int, known: Int)
    /// An older file with no step to raise it. A bug in this build, not in the file.
    case noMigrationPath(from: Int)
    /// A Logbook-shaped file this build's model cannot decode.
    case malformed(String)
}

extension LogbookFileError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .notJSON:
            "The file is not JSON."
        case .noSchemaVersion:
            "The file has no schemaVersion, so it is not a Hoppa logbook."
        case .fromNewerBuild(let found, let known):
            "The file was written by a newer version of Hoppa (schema \(found), this build knows \(known))."
        case .noMigrationPath(let from):
            "This build has no migration step from schema version \(from)."
        case .malformed(let detail):
            "The logbook could not be decoded: \(detail)"
        }
    }
}
