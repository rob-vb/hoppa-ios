import SwiftUI
import HoppaRules

// Ticket 0032 — the navigation spine.
//
// §6.7 names **two doors and no tab bar**, so the shape is one `NavigationStack` whose
// path lives in `@State` on the root view, per
// [The view layer around the rules](0024-the-view-layer-around-the-rules.md). There is no
// router object and no navigation state in the store: a path is view state, and the store
// may not hold view state.

/// Every screen the app can push. One case per screen ticket, so a ticket that lands its
/// screen swaps one `case` in `HoppaApp`'s `navigationDestination` and touches nothing else.
enum Route: Hashable {
    /// Flow 1, §6.1 step 1 — name the Program and read the three assumptions.
    case createProgram
    /// §5.2's Plate Inventory, which is **two things behind one screen**.
    ///
    /// With a draft it is §6.1 **step 2**: the confirm creates the Program the draft
    /// describes and lands on step 3. Without one it is the rack on its own, reached
    /// from Flow 5, and the confirm only leaves. The rack itself is Logbook-level and
    /// identical either way — Hoppa holds **one** Plate Inventory (§5.2) — so there is
    /// one screen and not two.
    case plateRack(ProgramDraft?)
    /// §6.1 step 3 and Flow 5's hub, which are **the same screen** — ticket 0034.
    ///
    /// `onboarding` is the third step of three and nothing else: it draws the step count
    /// and it makes the bottom control read `START A WORKOUT` instead of `DONE`. It
    /// cannot be derived from the Logbook — a Program reached from the picker and a
    /// Program just created look identical the moment the first Day is added — and it is
    /// the same distinction `PlateRackScreen` draws from `draft == nil`.
    case programSheet(ProgramID, onboarding: Bool)
    /// One Workout Day and the Exercises in it — ticket 0034, under the hub.
    case workoutDay(WorkoutDayID)
    /// §6.6's Program-level edits: the Name, and the three decisions step 1 pre-answered.
    /// The hub links to it, and it is the **only** door to the Plate Inventory outside
    /// onboarding — ticket 0034.
    case programSettings(ProgramID)
    /// Flow 2, §6.4, the screen at the rack — ticket 0036.
    ///
    /// It carries the Workout Day it was picked from rather than reading the Open Workout,
    /// because **the picker does not start the Workout yet**: ticket 0036 owns
    /// `.startWorkout`, so that a tap here cannot strand an Open Workout on the phone with
    /// no screen to finish or discard it.
    case logging(WorkoutDayID)
    /// Flow 3, §6.5 — ticket 0038, and ticket 39 adds the confetti to it.
    ///
    /// It carries the **finished** Workout's id and not the Day's: the Summary is a
    /// statement about one performance, and by the time it is on screen there is no Open
    /// Workout left to read.
    case summary(WorkoutID)
    /// Flow 4, §6.7 — not scheduled. Held in the map's **Not yet specified**.
    case history
}

/// The door is real, the room is not.
///
/// Ticket 0032 offered *disabled or absent* for a door to an unbuilt screen and this is a
/// third answer, taken on purpose. A disabled row proves nothing about the spine, and the
/// spine is what this ticket is for. Ticket 0029's hand-off rule wants **what is not built
/// yet** stated so a missing thing is never reported as a defect; a screen that says so in
/// its own words is the shortest way to keep that promise.
struct NotBuiltYet: View {
    let screen: String
    let ticket: String

    var body: some View {
        ZStack {
            Color.floor.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 16) {
                Text("Not built yet")
                    .typography(Typography.display(26))
                    .foregroundStyle(Color.text)
                Text(screen)
                    .typography(Typography.body(13, lineSpacing: 4))
                    .foregroundStyle(Color.dimText)
                Text("Ticket \(ticket)")
                    .typography(Typography.label())
                    .foregroundStyle(Color.labelText)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
        }
        .toolbarBackground(Color.floor, for: .navigationBar)
    }
}
