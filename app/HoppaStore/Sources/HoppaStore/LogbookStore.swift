import Foundation
import HoppaRules
import Observation

/// The one thing between `HoppaRules` and the screens: it holds the `Logbook`, forwards
/// every action to `Rules.reduce`, and saves.
///
/// **It decides nothing.** The moment it grows an `if` about training, rules live in two
/// places and ticket 20's boundary is gone. There is one mutating method, `send`, and its
/// whole body is reduce-then-save.
///
/// > Decisions: [The view layer around the rules](../../../../issues/0024-the-view-layer-around-the-rules.md),
/// > [Persistence and the data model](../../../../issues/0019-persistence-and-the-data-model.md).
@MainActor
@Observable
public final class LogbookStore {

    /// What loading the file produced. `.unreadable` carries **no `Logbook`**: an empty
    /// Logbook plus a failure flag looks exactly like a fresh install with every Workout
    /// gone, which is a lie told at the worst possible moment.
    public enum LoadState {
        /// No file yet. A fresh install is `Logbook.empty`, and it is not written until
        /// the first real mutation.
        case empty
        case loaded(Logbook)
        case unreadable(any Error)
    }

    public private(set) var state: LoadState

    /// The last save that failed, or `nil`. Views may show it; nothing here retries.
    /// A silent failure in the one piece of code that can lose weeks of training is not
    /// a failure worth having.
    public private(set) var lastSaveError: (any Error)?

    /// Where `logbook.json` lives. A `URL` and not a protocol, so the tests run the real
    /// atomic write and the real backup rather than an in-memory stand-in of them.
    public let url: URL

    /// The clock enters here and nowhere else. `Rules.reduce` takes it as an argument;
    /// no rule may reach for one.
    private let now: () -> Timestamp

    public init(url: URL, now: @escaping () -> Timestamp = { Date().timeIntervalSince1970 }) {
        self.url = url
        self.now = now
        self.state = Self.load(from: url)
    }

    /// The `Logbook` a view may render, or `nil` when the file could not be read.
    ///
    /// `.empty` yields a real Logbook — §6.1's kg rack and nothing else — because a fresh
    /// install has training ahead of it. `.unreadable` yields nothing, so no view can
    /// render a screen and no view can call `send`.
    public var logbook: Logbook? {
        switch state {
        case .empty: Logbook.empty
        case .loaded(let logbook): logbook
        case .unreadable: nil
        }
    }

    public var isUnreadable: Bool {
        if case .unreadable = state { return true }
        return false
    }

    // MARK: - The one way in

    /// Reduce, then save. Nothing else.
    ///
    /// An action the rules refuse changes nothing, so it writes nothing — which is also
    /// what keeps a fresh install from putting a file on disk before there is anything
    /// in it.
    ///
    /// > The first guard is the one that matters, and **that day has come**. It was
    /// > written when `Logbook.empty` was a fixed point under every action there was —
    /// > all twelve needed an Open Workout or a Program, and an empty Logbook has
    /// > neither — so no test could fail it. §6.6's `createProgram` ends that: a store
    /// > that fell back to `.empty` on `.unreadable` now writes a brand-new Program over
    /// > a logbook Hoppa merely failed to *read*. `StoreTests` fails it on purpose.
    public func send(_ action: Action) {
        guard let current = logbook else { return }
        let next = Rules.reduce(current, action, at: now())
        guard next != current else { return }
        state = .loaded(next)
        save(next)
    }

    // MARK: - Loading

    private static func load(from url: URL) -> LoadState {
        // A missing file is a fresh install. An existing file that will not open is not.
        guard FileManager.default.fileExists(atPath: url.path) else { return .empty }
        do {
            let data = try Data(contentsOf: url)
            let version = try LogbookFile.version(in: data)
            if version < Logbook.currentSchemaVersion {
                // Before anything touches it. Once the first save lands, the original
                // bytes are gone, and a migration that went wrong has nothing to go back
                // to. A failed backup stops the load rather than migrating unprotected.
                try backUp(data, from: version, beside: url)
            }
            return .loaded(try LogbookFile.decode(data))
        } catch {
            // The file is left exactly as it is. This is the rule that protects weeks of
            // real training: Hoppa never writes over something it could not read.
            return .unreadable(error)
        }
    }

    /// `logbook-v<n>-backup.json`, beside the logbook.
    private static func backUp(_ data: Data, from version: Int, beside url: URL) throws {
        let backup = url
            .deletingLastPathComponent()
            .appendingPathComponent("logbook-v\(version)-backup.json")
        try data.write(to: backup, options: [.atomic])
    }

    // MARK: - Saving

    private func save(_ logbook: Logbook) {
        do {
            let data = try LogbookFile.encode(logbook)
            // `.atomic` **is** write-to-a-temporary-file-then-rename, done by the
            // platform: Foundation writes a sibling temporary and `rename(2)`s it over
            // the target. Hand-rolling it would mean hand-rolling the one code path that
            // must behave identically on Darwin and on Linux, where the tests run.
            try data.write(to: url, options: [.atomic])
            lastSaveError = nil
        } catch {
            lastSaveError = error
        }
    }
}
