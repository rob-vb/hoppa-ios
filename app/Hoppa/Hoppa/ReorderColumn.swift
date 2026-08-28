import SwiftUI

// Ticket 0044 — §6.6's reorder handles, and the list that moves under them.
//
// One column of cards, dragged into a new order by a handle on the leading edge. It draws
// the card chrome — 62 pt, `card`, a 1 px `line` stroke — so a row builder hands it content
// and nothing else, and the two lists that need it look the same because they *are* the
// same view.
//
// **It decides nothing.** The drop hands an id and a position to `HoppaRules`, which owns
// the whole of §6.6's reorder rule: the Day's list moves, and — for an Exercise — the Open
// Workout's list moves with it while `currentIndex` follows the **Exercise** and not the
// position (§6.4). The arithmetic under the finger is `ReorderDrag`, which imports nothing
// and is walked by `app/checks/Reorder/run.sh`; what is left in this file is the drawing.
//
// ## Three things this is not, and why
//
// - **Not `List` + `.onMove`.** `.onMove` needs `EditMode.active` to show a grabber, and a
//   row in edit mode stops answering taps — which would cost both lists the one thing they
//   are for (*tap a row to open it*). A `List` reordered by long press instead has no
//   visible handle at all, and this app already refused that trade once: `RENAME` is a word
//   on the screen rather than something hiding behind a long press.
// - **Not a mode.** Hoppa has no edit mode anywhere, so an edit mode here would need a
//   `DONE` that means nothing. The handles are always on the rows.
// - **Not an SF Symbol.** The grip is three drawn bars, like every other glyph in this app
//   (§7.1). One imported symbol set would be a §7 decision nobody has made.
//
// The handle carries its own `DragGesture` and sits **beside** the row's Button rather than
// over it: the handle drags, the rest of the card taps, and the ScrollView keeps every pixel
// that is neither.
//
// **That last clause was too generous, and ticket 0054 corrects it.** The handle's pixels
// are inside a vertical `ScrollView` at both call sites, and a vertical drag there is a
// competition the ScrollView can win. So the drag is a `highPriorityGesture` and the
// caller's ScrollView is pinned by `isReordering` while a handle is held — a reorder and a
// scroll must never run at the same time.
struct ReorderColumn<Item, Key: Hashable, Row: View>: View {
    let items: [Item]
    let id: KeyPath<Item, Key>
    let rowHeight: CGFloat
    let spacing: CGFloat
    /// Where the drop landed: the item that moved, and the position it now holds. The
    /// caller sends the `Action`; this view has already forgotten the drag.
    let drop: (Key, Int) -> Void
    /// The row's content, and **the position it is drawn at** — which under a finger is the
    /// previewed one, not the stored one, so a numbered list renumbers before the drop.
    let row: (Item, Int) -> Row
    /// True while a handle is held. **The caller's ScrollView must stop scrolling on it**
    /// — see the note on the shake below. It is reported rather than owned here because
    /// `scrollDisabled` only works on the ScrollView itself, and this view is inside it.
    @Binding var isReordering: Bool

    init(
        items: [Item],
        id: KeyPath<Item, Key>,
        rowHeight: CGFloat = 62,
        spacing: CGFloat = 6,
        isReordering: Binding<Bool> = .constant(false),
        drop: @escaping (Key, Int) -> Void,
        @ViewBuilder row: @escaping (Item, Int) -> Row
    ) {
        self.items = items
        self.id = id
        self.rowHeight = rowHeight
        self.spacing = spacing
        self._isReordering = isReordering
        self.drop = drop
        self.row = row
    }

    /// The item under the finger. `nil` means no drag is running.
    @State private var dragging: Key?
    /// How far the finger has travelled, in points.
    @State private var travel: CGFloat = 0

    /// The drag as `ReorderDrag` holds it, or `nil` when no finger is down. Rebuilt on
    /// every pass off `items`, so a list that changes under the drag cannot leave a stale
    /// index behind.
    private var drag: ReorderDrag? {
        guard let dragging, let origin = items.firstIndex(where: { $0[keyPath: id] == dragging })
        else { return nil }
        return ReorderDrag(
            origin: origin, count: items.count,
            pitch: Double(rowHeight + spacing), travel: Double(travel))
    }

    /// An item with its key and its stored position, because `ForEach` needs an
    /// `Identifiable` and a key path cannot be built through a tuple.
    private struct Entry: Identifiable {
        let id: Key
        let index: Int
        let item: Item
    }

    private var entries: [Entry] {
        items.enumerated().map {
            Entry(id: $0.element[keyPath: id], index: $0.offset, item: $0.element)
        }
    }

    var body: some View {
        VStack(spacing: spacing) {
            ForEach(entries) { entry in
                card(index: entry.index, item: entry.item)
            }
        }
        // One tick as each row displaces, because a drag is watched by the thumb and not by
        // the eye. Haptics are not motion, so Reduce Motion does not reach this.
        .sensoryFeedback(.selection, trigger: drag?.landing)
        // **The lock is derived, never set by hand.** Writing `isReordering` from the
        // gesture's two callbacks would mean two places that can leave it true — and a
        // ScrollView stuck at `scrollDisabled(true)` is a worse defect than the shake it
        // was added to fix. `dragging` is the single truth; the lock follows it.
        .onChange(of: dragging) { _, now in isReordering = now != nil }
        // A cancelled gesture does not always call `onEnded`. Leaving the screen clears
        // the drag, so a list can never come back locked.
        .onDisappear {
            dragging = nil
            travel = 0
        }
    }

    private func card(index: Int, item: Item) -> some View {
        let lifted = dragging == item[keyPath: id]
        let shift = CGFloat(drag?.shift(index) ?? 0)
        return HStack(spacing: 0) {
            handle(item[keyPath: id])
            row(item, drag?.position(index) ?? index)
        }
        .frame(height: rowHeight)
        .background(Color.card)
        .overlay(
            RoundedRectangle(cornerRadius: 3)
                .stroke(lifted ? Color.steel : Color.line, lineWidth: 1))
        // A lifted card is above the ones it passes, and casts the only shadow in the app.
        //
        // **Radius 0 and a clear colour when it is not lifted, not opacity 0.** A shadow
        // is an offscreen blur pass, and a shadow that is merely transparent still costs
        // one — on every card, on every frame of a drag. Ticket 0054.
        .shadow(
            color: lifted ? .black.opacity(0.45) : .clear,
            radius: lifted ? 10 : 0, y: lifted ? 4 : 0)
        .zIndex(lifted ? 1 : 0)
        .offset(y: shift)
        // The dragged card follows the finger with nothing between it and the skin; the
        // ones it displaces slide, which is how the drop target is read.
        .animation(lifted ? nil : Animation.easeOut(duration: 0.14), value: shift)
    }

    /// Three bars at §7.4's hit target, and the whole of the drag.
    private func handle(_ key: Key) -> some View {
        VStack(spacing: 3) {
            ForEach(0..<3, id: \.self) { _ in
                Capsule()
                    .fill(dragging == key ? Color.steel : Color.labelText)
                    .frame(width: 15, height: 1.5)
            }
        }
        .frame(width: 36, height: rowHeight)
        .contentShape(Rectangle())
        // ## The shake, and the two things that caused it (ticket 0054)
        //
        // **`coordinateSpace: .global`, and it is not a detail.** A `DragGesture` reports
        // `translation` as `location - startLocation`, both read in the gesture's
        // coordinate space — and the default, `.local`, is *this handle's* space, which
        // sits inside the card that `offset(y:)` is moving by the very number being
        // measured. Move the finger 10 pt: translation reads 10, the card offsets 10, and
        // on the next event the space has moved 10 with it, so translation reads 0 and the
        // card snaps back. **That is an oscillation at frame rate**, and it is what a shake
        // is. The screen does not move, so `.global` cannot feed back.
        //
        // **`highPriorityGesture`, because this list lives in a `ScrollView`.** Both call
        // sites scroll, and a vertical drag on a child of a vertical scroll view is a
        // competition. Losing it half the time means the content slides under the finger
        // while the card offsets against it — a second, independent shake, on top of a
        // list that scrolls when the user meant to reorder. High priority settles the
        // competition at the start; `isReordering` pins the ScrollView for the duration,
        // because a reorder and a scroll must never run together.
        .highPriorityGesture(
            DragGesture(minimumDistance: 2, coordinateSpace: .global)
                .onChanged { value in
                    if dragging == nil { dragging = key }
                    travel = value.translation.height
                }
                .onEnded { _ in
                    if let drag, drag.landing != drag.origin {
                        drop(items[drag.origin][keyPath: id], drag.landing)
                    }
                    dragging = nil
                    travel = 0
                })
    }
}
