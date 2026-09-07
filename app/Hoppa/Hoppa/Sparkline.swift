import SwiftUI
import HoppaRules

// Ticket 0050 — §6.7's sparkline. Ticket 0058 — where it lives now.
//
// **The mark is decoration on a row that is itself the door.** It sits on a Progress row,
// between the Exercise's figures and the chevron, and it owns no gesture: tapping the mark
// is tapping the row, the way tapping the date on a History row is tapping the row. It is
// hidden from accessibility for the same reason — the row's own label says what it opens.
//
// It was not born there. Ticket 0050 put it on the Exercise card in the Workout Day screen
// as a nested button, *the* door to the chart, beside the sheet's own tap target. Ticket
// 0058 moved the door to the Progress page and took the mark with it; the card is grip and
// sheet again. Nothing about the drawing changed, which is the point of the drawing being
// its own file.
//
// **The view holds no arithmetic**, exactly as `ExerciseChartScreen` holds none. Every
// point is `ExerciseChart.sparkline`, carried on the `ProgressRow` — the chart's own line,
// on the chart's own `ChartScale`, on the chart's own real-time x axis — so the mark on the
// row and the line on the screen it opens can never draw two different climbs. What is left
// here is 44 × 16 points of pixels.
//
// **2 px steel**, like the chart's line. §7.1's rule that no plate colour ever enters a
// chart does not stop at the chart's edge: a coloured mark on a row would claim to be a
// plate. Green is not used either — on the chart green marks *one session*, and a green
// dot alone on a row would read as a verdict on the Exercise. The row's own green line,
// `3 went up`, is already the verdict in words.
//
// Artboard: `design/0015-history/Program.dc.html`, which draws it on the card at 54 × 20
// and 1.5 px. Historical on both counts: `SPEC.md` set 2 px to match the line it copies,
// and the card no longer carries it.

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
            // session honestly looks like, and the row still opens the screen that
            // states the hero and the condition for the next step.
            context.fill(
                Path(ellipseIn: CGRect(
                    x: last.x - Self.dot, y: last.y - Self.dot,
                    width: Self.dot * 2, height: Self.dot * 2)),
                with: .color(Color.steel))
        }
        .frame(width: Self.width, height: Self.height)
        // The mark is a picture of a series that is stated in words one tap away, and
        // the row it sits on carries the label.
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
