/// Identity is a stored id, never a Name (`SPEC.md` §2.7, §2.8).
///
/// An `Int` counter and not a `UUID`, for two reasons: `UUID` lives in Foundation, and
/// the committed 56-Workout snapshot has to be byte-stable across re-records.
/// An id is **never reused** after a delete.
public protocol EntityID: Codable, Sendable, Hashable, CustomStringConvertible {
    var value: Int { get }
    init(_ value: Int)
}

extension EntityID {
    public init(from decoder: any Decoder) throws {
        self.init(try decoder.singleValueContainer().decode(Int.self))
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }

    public var description: String { "\(value)" }
}

public struct ProgramID: EntityID {
    public let value: Int
    public init(_ value: Int) { self.value = value }
}

public struct WorkoutDayID: EntityID {
    public let value: Int
    public init(_ value: Int) { self.value = value }
}

public struct ExerciseID: EntityID {
    public let value: Int
    public init(_ value: Int) { self.value = value }
}

public struct WorkoutID: EntityID {
    public let value: Int
    public init(_ value: Int) { self.value = value }
}
