/// Seconds since the Unix epoch.
///
/// The clock never lives inside a rule. Every action that needs one takes it as the
/// `at:` argument of `Rules.reduce`, and the app maps `Date` to this at the boundary.
public typealias Timestamp = Double
