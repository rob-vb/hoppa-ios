import Foundation

/// Where the committed fixtures live, found from this file rather than from a resource
/// bundle: the tests both read them and re-record them.
enum Recording {
    static var directory: URL {
        URL(fileURLWithPath: #filePath).deletingLastPathComponent()
    }

    /// `HOPPA_RECORD=1 swift test` rewrites the committed files instead of checking them.
    /// Only ever set this when a rule changed on purpose — the diff is the review.
    static var isRecording: Bool {
        ProcessInfo.processInfo.environment["HOPPA_RECORD"] == "1"
    }

    /// Stable JSON: sorted keys and no escaped slashes, so a re-record with nothing
    /// changed produces a zero-line diff.
    static var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted, .withoutEscapingSlashes]
        return encoder
    }

    /// Compares `produced` against the committed file, or rewrites it when recording.
    /// Returns the text the file should hold, and whether it matched.
    static func check(_ produced: String, against path: String) throws -> (matched: Bool, committed: String?) {
        let url = directory.appendingPathComponent(path)
        if isRecording {
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try produced.write(to: url, atomically: true, encoding: .utf8)
            return (true, produced)
        }
        guard let committed = try? String(contentsOf: url, encoding: .utf8) else {
            return (false, nil)
        }
        return (committed == produced, committed)
    }

    /// The first line that differs, so a failure names the key instead of dumping the file.
    static func firstDifference(_ a: String, _ b: String) -> String {
        let left = a.split(separator: "\n", omittingEmptySubsequences: false)
        let right = b.split(separator: "\n", omittingEmptySubsequences: false)
        for index in 0..<max(left.count, right.count) {
            let l = index < left.count ? String(left[index]) : "<end of file>"
            let r = index < right.count ? String(right[index]) : "<end of file>"
            if l != r { return "line \(index + 1):\n  committed: \(l)\n  produced:  \(r)" }
        }
        return "no line differs"
    }
}
