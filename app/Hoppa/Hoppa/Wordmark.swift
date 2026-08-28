import SwiftUI

// Ticket 0057 — Rob's wordmark, placed where it is read once and then ignored.
//
// `hoppa.svg` is five letters, drawn by Rob, in the asset catalogue as a template image
// with its vector data kept — so it is one file, tinted by whatever `foregroundStyle` the
// caller sets, and sharp at any height. **No view holds a colour literal** (§7.2): the
// SVG's own `#FCFCFC` is discarded by template rendering and a palette role stands in.
//
// **Subtle means two things here.** It is small, and it is in a quiet grey — never the
// hero. It sits on the picker because the picker is home (§6.1), and on the first run
// because that screen has no header and nothing else says whose app this is.

/// The wordmark at a given height, width following the SVG's 547 : 218.
struct Wordmark: View {
    let height: CGFloat

    var body: some View {
        Image("Wordmark")
            .resizable()
            .renderingMode(.template)
            .aspectRatio(547.0 / 218.0, contentMode: .fit)
            .frame(height: height)
            .accessibilityLabel("Hoppa")
    }
}
