import SwiftUI
import UIKit
import CoreText

// Ticket 0018 — the smoke test screen.
//
// One screen that proves four things at once: the app signs and launches on the
// phone, the surface palette (SPEC.md §7.2) renders on a real display, both
// bundled faces (§7.4) load, and Anton draws the hero number.
//
// The verdict block below is the point of the screen. A missing font falls back
// to the system face silently, and at a glance the number would still look
// plausible — so the screen asks CoreText whether each face really registered
// and states the answer instead of leaving it to the eye.

// MARK: - Bundled fonts

/// Registers the bundled faces with CoreText at launch.
///
/// This is deliberately runtime registration rather than an `UIAppFonts` entry
/// in the Info.plist: a modern Xcode project generates its Info.plist from build
/// settings, so there is no plist file to edit, and this route needs no step in
/// the Xcode UI at all. `UIAppFonts` remains the conventional alternative and
/// can replace this later.
enum BundledFonts {
    /// PostScript names — read from the font files themselves. They are not
    /// guessable from the filenames: IBM's medium weight is `IBMPlexSans-Medm`.
    static let display = "Anton-Regular"
    static let body = "IBMPlexSans"
    static let bodyMedium = "IBMPlexSans-Medm"

    private static let files = ["Anton-Regular", "IBMPlexSans-Regular", "IBMPlexSans-Medium"]

    static func register() {
        for file in files {
            guard let url = locate(file) else {
                print("[smoke] font file not in the bundle: \(file).ttf")
                continue
            }
            var error: Unmanaged<CFError>?
            if !CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error) {
                let reason = error?.takeRetainedValue().localizedDescription ?? "unknown"
                print("[smoke] could not register \(file).ttf — \(reason)")
            }
        }
    }

    /// The Fonts folder may land flattened into the bundle root or kept as a
    /// subdirectory, depending on how Xcode added it. Look in both.
    private static func locate(_ file: String) -> URL? {
        Bundle.main.url(forResource: file, withExtension: "ttf")
            ?? Bundle.main.url(forResource: file, withExtension: "ttf", subdirectory: "Fonts")
    }

    /// True when CoreText can actually resolve the PostScript name, so a silent
    /// fallback to the system face cannot pass as a success.
    static func isAvailable(_ postScriptName: String) -> Bool {
        UIFont(name: postScriptName, size: 12) != nil
    }
}

// MARK: - Surface palette (SPEC.md §7.2)

private extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }

    static let floor = Color(hex: 0x0E0F10)
    static let card = Color(hex: 0x17191B)
    static let line = Color(hex: 0x26292C)
    static let steel = Color(hex: 0x9BA1A7)
    static let dimText = Color(hex: 0x8D9296)
    static let text = Color(hex: 0xF4F1EC)
    static let go = Color(hex: 0x2E9E52)      // green — done / progression
    static let stop = Color(hex: 0xC8322B)    // 25 kg red
}

// MARK: - The screen

struct ContentView: View {
    private let checks: [(face: String, name: String)] = [
        ("Anton", BundledFonts.display),
        ("IBM Plex Sans", BundledFonts.body),
        ("IBM Plex Sans Medium", BundledFonts.bodyMedium),
    ]

    var body: some View {
        ZStack {
            Color.floor.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 32) {
                Spacer(minLength: 0)
                hero
                Divider().overlay(Color.line)
                verdict
                Spacer(minLength: 0)
                footer
            }
            .padding(.horizontal, 20)   // screen padding 20 px (§7.4)
            .padding(.top, 54)          // safe top inset, nothing drawn in it
            .padding(.bottom, 20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("WORKING WEIGHT")
                .font(.custom(BundledFonts.bodyMedium, fixedSize: 11))
                .tracking(1.4)
                .foregroundStyle(Color.dimText)

            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text("72.5")
                    .font(.custom(BundledFonts.display, fixedSize: 108))
                    .foregroundStyle(Color.text)
                Text("KG")
                    .font(.custom(BundledFonts.display, fixedSize: 34))
                    .foregroundStyle(Color.steel)
            }
        }
    }

    private var verdict: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(checks.enumerated()), id: \.offset) { index, check in
                if index > 0 {
                    Rectangle().fill(Color.line).frame(height: 1)
                }
                row(face: check.face, postScriptName: check.name)
            }
        }
        .background(Color.card)
        .clipShape(RoundedRectangle(cornerRadius: 2))   // radii 2–3 px (§7.4)
    }

    private func row(face: String, postScriptName: String) -> some View {
        let loaded = BundledFonts.isAvailable(postScriptName)
        return HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(face)
                    .font(.custom(BundledFonts.body, fixedSize: 15))
                    .foregroundStyle(Color.text)
                Text(postScriptName)
                    .font(.custom(BundledFonts.body, fixedSize: 12))
                    .foregroundStyle(Color.dimText)
            }
            Spacer()
            Text(loaded ? "LOADED" : "FALLBACK")
                .font(.custom(BundledFonts.bodyMedium, fixedSize: 11))
                .tracking(1.4)
                .foregroundStyle(loaded ? Color.go : Color.stop)
        }
        .padding(.horizontal, 16)
        .frame(height: 50)   // hit target 50 px (§7.4)
    }

    private var footer: some View {
        Text("Smoke test · ticket 0018")
            .font(.custom(BundledFonts.body, fixedSize: 12))
            .foregroundStyle(Color.dimText)
    }
}

#Preview {
    // A preview never runs `HoppaApp.init`, so register the faces here too —
    // otherwise the canvas reports FALLBACK on a build that is in fact fine.
    BundledFonts.register()
    return ContentView().preferredColorScheme(.dark)
}
