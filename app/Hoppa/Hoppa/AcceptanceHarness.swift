import SwiftUI
import HoppaRules
import HoppaStore

// Ticket 0025 — "The Logbook on disk".
//
// **This is a harness, not a screen.** It is the smallest thing that can prove the one
// claim the ticket is about: start a Workout, log two Sets, force-quit, reopen, and the
// Open Workout is still there with both Sets at the same Exercise. Flow 2 is a later
// ticket, and none of the layout below is a design decision.
//
// It replaces ticket 0018's font smoke test, whose verdict block is kept at the bottom so
// the fonts stay checkable on the device.

struct AcceptanceHarness: View {
    @Environment(LogbookStore.self) private var store

    var body: some View {
        ZStack {
            Color.floor.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if store.isUnreadable {
                        unreadable
                    } else {
                        state
                        controls
                    }
                    file
                    fonts
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 32)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    // MARK: - What a corrupt file looks like

    /// The whole of what a view may do with `.unreadable`: say what is true. There is no
    /// Logbook in hand, so there is nothing to render and nothing to send.
    private var unreadable: some View {
        VStack(alignment: .leading, spacing: 8) {
            label("LOGBOOK")
            Text("Hoppa cannot read your logbook.\nNothing was changed.")
                .font(.custom(BundledFonts.body, fixedSize: 17))
                .foregroundStyle(Color.stop)
        }
    }

    // MARK: - The claim under test

    private var state: some View {
        let workout = store.logbook?.openWorkout
        let performed = workout?.exercises.first
        return VStack(alignment: .leading, spacing: 8) {
            label("OPEN WORKOUT")
            Text(workout?.workoutDayName ?? "none")
                .font(.custom(BundledFonts.display, fixedSize: 44))
                .foregroundStyle(Color.text)
            row("Exercise", performed?.name ?? "—")
            row("Current index", "\(workout?.currentIndex ?? -1)")
            row("Sets logged", "\(performed?.sets.count ?? 0)")
            row("Reps", reps(of: performed))
            row("Finished Workouts", "\(store.logbook?.workouts.count ?? 0)")
        }
    }

    private var controls: some View {
        VStack(spacing: 8) {
            if store.logbook?.openWorkout == nil {
                button("START WORKOUT") {
                    guard let program = store.logbook?.programs.first,
                          let day = program.days.first else { return }
                    store.send(.startWorkout(programId: program.id, workoutDayId: day.id))
                }
            } else {
                button("LOG SET") { store.send(.logSet(reps: targetReps)) }
                button("DISCARD") { store.send(.discard) }
            }
        }
    }

    // MARK: - The file itself, so the proof is checkable on the phone

    private var file: some View {
        let url = Logbook.fileURL
        let size = (try? Data(contentsOf: url).count) ?? 0
        return VStack(alignment: .leading, spacing: 8) {
            label("ON DISK")
            row("logbook.json", size == 0 ? "not written yet" : "\(size) bytes")
            if let error = store.lastSaveError {
                row("Last save", "FAILED — \(error)")
            }
            Text(url.path)
                .font(.custom(BundledFonts.body, fixedSize: 11))
                .foregroundStyle(Color.dimText)
        }
    }

    // MARK: - Kept from ticket 0018

    private var fonts: some View {
        VStack(alignment: .leading, spacing: 8) {
            label("FONTS")
            ForEach([BundledFonts.display, BundledFonts.body, BundledFonts.bodyMedium], id: \.self) {
                row($0, BundledFonts.isAvailable($0) ? "LOADED" : "FALLBACK")
            }
        }
    }

    // MARK: - Plain parts

    /// The keypad and the rep counter are Flow 2's. Target Reps will do here.
    private var targetReps: Int {
        guard let logbook = store.logbook,
              let performed = logbook.openWorkout?.current,
              let resolved = logbook.resolvedExercise(performed.exerciseId)
        else { return 10 }
        return resolved.targetReps
    }

    private func reps(of performed: PerformedExercise?) -> String {
        guard let sets = performed?.sets, !sets.isEmpty else { return "—" }
        return sets.map { "\($0.reps)" }.joined(separator: ", ")
    }

    private func label(_ text: String) -> some View {
        Text(text)
            .font(.custom(BundledFonts.bodyMedium, fixedSize: 11))
            .tracking(1.4)
            .foregroundStyle(Color.dimText)
    }

    private func row(_ name: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(name)
                .font(.custom(BundledFonts.body, fixedSize: 14))
                .foregroundStyle(Color.dimText)
            Spacer(minLength: 12)
            Text(value)
                .font(.custom(BundledFonts.bodyMedium, fixedSize: 14))
                .foregroundStyle(Color.text)
                .multilineTextAlignment(.trailing)
        }
    }

    private func button(_ title: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.custom(BundledFonts.bodyMedium, fixedSize: 13))
                .tracking(1.4)
                .foregroundStyle(Color.text)
                .frame(maxWidth: .infinity)
                .frame(height: 50)          // hit target 50 px (§7.4)
                .background(Color.card)
                .clipShape(RoundedRectangle(cornerRadius: 2))
        }
    }
}
