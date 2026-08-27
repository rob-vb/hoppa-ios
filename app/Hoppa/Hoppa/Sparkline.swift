import SwiftUI
import HoppaRules

// Ticket 0050 — §6.7's sparkline, and the second door on an Exercise card.
//
// *"Any **Exercise card** in the Program sheet → That Exercise's chart. The card carries a
// sparkline, so the door announces itself."*
//
// **The announcement and the door are one object.** That is the decision ticket 0050 took,
// and this file is the whole of it: the mark is the tap target, the rest of the card still
// opens §6.2's Exercise sheet, and an Exercise with nothing to plot draws no mark and so
// offers no second door. See `ExerciseChart.hasSpark` for the reasoning; `WorkoutDayScreen`
// is where the two targets sit beside each other.
//
// **The view holds no arithmetic**, exactly as `ExerciseChartScreen` holds none. Every
// point is `ExerciseChart.sparkline` — the chart's own line, on the chart's own
// `ChartScale`, on the chart's own real-time x axis — so the mark on the card and the line
// on the screen it opens can never draw two different climbs. What is left here is 44 × 16
// points of pixels.
//
// **2 px steel**, like the chart's line. §7.1's rule that no plate colour ever enters a
// chart does not stop at the chart's edge: a coloured mark on a card would claim to be a
// plate. Green is not used either — on the chart green marks *one session*, and a green
// dot alone on a card would read as a verdict on the Exercise.
//
// Artboard: `design/0015-history/Program.dc.html`, which draws it 54 × 20 at 1.5 px.
// `SPEC.md` beats the artboard: the ticket sets 2 px, to match the line it is a copy of.

struct Sparkline: View {
    /// `ExerciseChart.sparkline` — fractions of this box, oldest first.
    let marks: [SparkPoint]

    static let width: CGFloat = 44
    static let height: CGFloat = 16

    private static let stroke: CGFloat = 2
    /// The filled dot the artboard ends every mark on: *here is where you are now*.
    private static let dot: CGFloat = 2.2
    /// Half the widest thing drawn, so neither the cap nor the dot is clipped by the box.
    private static var inset: CGFloat { max(stroke / 2, dot) }

    var body: some View {
        Canvas { context, size in
            let plotted = points(in: size)
            guard let last = plotted.last else { return }
            if plotted.count > 1 {
                var path = Path()
                for (index, at) in plotted.enumerated() {
                    if index == 0 { path.move(to: at) } else { path.addLine(to: at) }
                }
                context.stroke(
                    path,
                    with: .color(Color.steel),
                    style: StrokeStyle(lineWidth: Self.stroke, lineCap: .round, lineJoin: .round))
            }
            // Drawn on one session as well as fifteen. A lone dot is what a single
            // session honestly looks like, and the card still opens the screen that
            // states the hero and the condition for the next step.
            context.fill(
                Path(ellipseIn: CGRect(
                    x: last.x - Self.dot, y: last.y - Self.dot,
                    width: Self.dot * 2, height: Self.dot * 2)),
                with: .color(Color.steel))
        }
        .frame(width: Self.width, height: Self.height)
        // The mark is a picture of a series that is stated in words one tap away.
        .accessibilityHidden(true)
    }

    /// `y` is `0` at the bottom of the plot and the screen's is `0` at the top, which is
    /// the one flip this file performs.
    private func points(in size: CGSize) -> [CGPoint] {
        let inset = Self.inset
        let usable = CGSize(width: size.width - inset * 2, height: size.height - inset * 2)
        return marks.map {
            CGPoint(
                x: inset + $0.x * usable.width,
                y: inset + (1 - $0.y) * usable.height)
        }
    }
}
