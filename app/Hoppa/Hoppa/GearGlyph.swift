import SwiftUI

// Ticket 0057, second pass — Rob: *"de 'drie puntjes' als settings icoon mag een tandwiel
// icoon zijn."* A gear, drawn and not imported: every glyph in this app comes out of a
// `Shape` or a bundled face (§7.1), and one SF Symbol would be a §7 decision nobody has
// made. Stroked, never filled — it is steel (§7.1 rule 2).

/// Eight teeth on a ring, with a hole. One `Path`, stroked once by the caller.
struct GearGlyph: Shape {
    var teeth = 8

    func path(in rect: CGRect) -> Path {
        let centre = CGPoint(x: rect.midX, y: rect.midY)
        let outer = min(rect.width, rect.height) / 2
        let inner = outer * 0.72
        let hole = outer * 0.3
        var path = Path()

        // The toothed outline: for each tooth, out along one flank, across the tip, back
        // down the other flank, then along the root to the next tooth.
        let step = (2 * Double.pi) / Double(teeth)
        let toothWidth = step * 0.42     // of the pitch, at the tip
        let rootWidth = step * 0.58      // of the pitch, at the root
        for tooth in 0..<teeth {
            let mid = Double(tooth) * step
            let a0 = mid - rootWidth / 2, a1 = mid - toothWidth / 2
            let a2 = mid + toothWidth / 2, a3 = mid + rootWidth / 2
            let p0 = point(centre, inner, a0), p1 = point(centre, outer, a1)
            let p2 = point(centre, outer, a2), p3 = point(centre, inner, a3)
            if tooth == 0 { path.move(to: p0) } else { path.addLine(to: p0) }
            path.addLine(to: p1)
            path.addLine(to: p2)
            path.addLine(to: p3)
            path.addArc(center: centre, radius: inner,
                        startAngle: .radians(a3), endAngle: .radians(a0 + step), clockwise: false)
        }
        path.closeSubpath()

        path.addEllipse(in: CGRect(x: centre.x - hole, y: centre.y - hole,
                                   width: hole * 2, height: hole * 2))
        return path
    }

    private func point(_ c: CGPoint, _ r: CGFloat, _ angle: Double) -> CGPoint {
        CGPoint(x: c.x + r * CGFloat(cos(angle)), y: c.y + r * CGFloat(sin(angle)))
    }
}
