/// The shipped Exercise Catalogue (`SPEC.md` §6.3): the second source under the user's
/// own names in the name field's ranked list.
///
/// **A plain array of strings, and nothing else.** A suggestion sets the Name and never
/// the Equipment Type or the Increment — the catalogue is a typing aid, not an inference
/// engine — so there is nothing else to store. It is not in a bundle because a bundle
/// buys only a file to lose.
///
/// It lives in `HoppaRules` and not beside the store, because the **ranking** §6.3
/// specifies reads both sources and de-duplicates across them: the catalogue is one half
/// of a rule's input, so it belongs where the rule is. See `Suggestions.swift` for the
/// other half.
///
/// Two conventions the list is checked against, both from §6.3:
///
/// - **Order is curated and fixed**, base movement above its variants, and it never
///   changes between two sessions. The qualifier trails the movement —
///   `Barbell Bench Press Close Grip`, the spec's own example — so a variant sorts under
///   what it varies, which alphabetical order would not do.
/// - **Equipment goes in front of a name only where it distinguishes**: as soon as the
///   same movement exists here on more than one Equipment Type, every one of them carries
///   a prefix. `Bench Press` is barbell, dumbbell and Smith, so all three are prefixed;
///   `Dip` is only itself, so it stays bare. `ExerciseCatalogueTests` checks this
///   mechanically, so a name added later cannot quietly break it.
public enum ExerciseCatalogue {

    /// About 150 names. ~50 leaves a first run typing in full too often, which is what
    /// the catalogue exists for; 500+ works against word-start matching, where `press`
    /// would return thirty rows.
    public static let names: [String] = [

        // MARK: Chest
        "Barbell Bench Press",
        "Barbell Bench Press Close Grip",
        "Barbell Bench Press Incline",
        "Barbell Bench Press Decline",
        "Dumbbell Bench Press",
        "Dumbbell Bench Press Incline",
        "Dumbbell Bench Press Decline",
        "Smith Machine Bench Press",
        "Smith Machine Bench Press Incline",
        "Machine Chest Press",
        "Machine Chest Press Incline",
        "Dumbbell Fly",
        "Dumbbell Fly Incline",
        "Machine Fly",
        "Cable Fly",
        "Cable Crossover",
        "Dumbbell Pullover",
        "Cable Pullover",
        "Push-up",
        "Push-up Close Grip",
        "Dip",
        "Dip Weighted",

        // MARK: Back
        "Pull-up",
        "Pull-up Weighted",
        "Pull-up Neutral Grip",
        "Chin-up",
        "Chin-up Weighted",
        "Lat Pulldown",
        "Lat Pulldown Wide Grip",
        "Lat Pulldown Close Grip",
        "Lat Pulldown Neutral Grip",
        "Cable Pulldown Straight Arm",
        "Barbell Row",
        "Barbell Row Pendlay",
        "Barbell Row Underhand",
        "Dumbbell Row",
        "Dumbbell Row Chest Supported",
        "Smith Machine Row",
        "Cable Row Seated",
        "Cable Row Single Arm",
        "Machine Row Seated",
        "Machine Row Chest Supported",
        "T-Bar Row",
        "Cable Face Pull",
        "Barbell Deadlift",
        "Barbell Deadlift Romanian",
        "Barbell Deadlift Stiff Leg",
        "Dumbbell Deadlift Romanian",
        "Trap Bar Deadlift",
        "Barbell Rack Pull",
        "Barbell Shrug",
        "Dumbbell Shrug",
        "Machine Shrug",
        "Back Extension",
        "Back Extension Weighted",

        // MARK: Shoulders
        "Barbell Overhead Press",
        "Barbell Overhead Press Seated",
        "Barbell Push Press",
        "Dumbbell Shoulder Press",
        "Dumbbell Shoulder Press Seated",
        "Dumbbell Shoulder Press Arnold",
        "Smith Machine Shoulder Press",
        "Machine Shoulder Press",
        "Dumbbell Lateral Raise",
        "Cable Lateral Raise",
        "Machine Lateral Raise",
        "Dumbbell Front Raise",
        "Cable Front Raise",
        "Dumbbell Rear Delt Fly",
        "Cable Rear Delt Fly",
        "Machine Rear Delt Fly",
        "Barbell Upright Row",
        "Cable Upright Row",
        "Barbell Landmine Press",

        // MARK: Biceps
        "Barbell Curl",
        "EZ-Bar Curl",
        "Dumbbell Curl",
        "Dumbbell Curl Hammer",
        "Dumbbell Curl Incline",
        "Dumbbell Curl Concentration",
        "Cable Curl",
        "Cable Curl Hammer",
        "Machine Curl",
        "Barbell Curl Preacher",
        "EZ-Bar Curl Preacher",
        "Dumbbell Curl Preacher",
        "Barbell Curl Reverse",
        "Cable Curl Reverse",

        // MARK: Triceps
        "Barbell Triceps Extension Lying",
        "EZ-Bar Triceps Extension Lying",
        "Dumbbell Triceps Extension Overhead",
        "Cable Triceps Extension Overhead",
        "Machine Triceps Extension",
        "Cable Triceps Pushdown",
        "Cable Triceps Pushdown Rope",
        "Cable Triceps Kickback",
        "Bench Dip",

        // MARK: Forearms
        "Barbell Wrist Curl",
        "Barbell Wrist Curl Reverse",
        "Dumbbell Wrist Curl",
        "Farmer's Walk",

        // MARK: Legs
        "Barbell Back Squat",
        "Barbell Back Squat Pause",
        "Barbell Back Squat Box",
        "Barbell Front Squat",
        "Smith Machine Squat",
        "Machine Hack Squat",
        "Dumbbell Goblet Squat",
        "Machine Leg Press",
        "Machine Leg Press Single Leg",
        "Barbell Lunge",
        "Dumbbell Lunge",
        "Dumbbell Lunge Walking",
        "Barbell Split Squat Bulgarian",
        "Dumbbell Split Squat Bulgarian",
        "Dumbbell Step-up",
        "Machine Leg Extension",
        "Machine Leg Extension Single Leg",
        "Machine Leg Curl Seated",
        "Machine Leg Curl Lying",
        "Barbell Hip Thrust",
        "Machine Hip Thrust",
        "Barbell Glute Bridge",
        "Cable Kickback Glute",
        "Machine Hip Abduction",
        "Machine Hip Adduction",
        "Barbell Good Morning",
        "Barbell Calf Raise Standing",
        "Dumbbell Calf Raise Standing",
        "Smith Machine Calf Raise Standing",
        "Machine Calf Raise Standing",
        "Machine Calf Raise Seated",
        "Machine Calf Raise Leg Press",

        // MARK: Core
        "Plank",
        "Plank Side",
        "Hanging Leg Raise",
        "Hanging Knee Raise",
        "Cable Crunch",
        "Machine Crunch",
        "Sit-up",
        "Sit-up Decline",
        "Ab Wheel Rollout",
        "Barbell Rollout",
        "Cable Woodchop",
        "Machine Torso Rotation",
        "Cable Pallof Press",
        "Dead Bug",
        "Hollow Hold",

        // MARK: Full body
        "Barbell Power Clean",
        "Barbell Hang Clean",
        "Barbell Clean and Jerk",
        "Barbell Snatch",
        "Kettlebell Swing",
        "Sled Push"
    ]

    /// The words that count as an Equipment Type prefix, longest first so
    /// `Smith Machine …` is never read as `Machine …`. Used by the mechanical check on
    /// the prefix rule, and by nothing at runtime.
    public static let equipmentPrefixes: [String] = [
        "Smith Machine", "Barbell", "Dumbbell", "Machine", "Cable",
        "Kettlebell", "EZ-Bar", "Trap Bar", "Sled"
    ]
}
