#!/usr/bin/env bash
# Ticket 0049 — draw §6.7's per-Exercise chart on this machine, and walk what it states.
#
# `ExerciseChartScreen.swift` imports SwiftUI, so it cannot be compiled here. `main.swift`
# is the thin ring around the parts of it that are not SwiftUI — the meta line, the chip,
# the weight text, the `Last sessions` rows and the three figures at the foot — plus a text
# renderer for the plot itself, so the shape of the line is visible without a phone.
# **That ring is a copy and it can rot**; keep it in step by hand when the screen changes.
# Same bargain as `app/checks/Past` and `app/checks/History`.
#
# This is the check the ticket was written around: §6.7 needs weeks of Workouts before it
# says anything, and the Logbook has none. `Rules.exerciseChart` is a rule, so sixteen
# weeks of it can be drawn here. The rule itself is not copied — it is the shipping call,
# linked from the built package, with its own suite in `HoppaRulesTests`.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
rules="$here/../../HoppaRules"
store="$here/../../HoppaStore"
out="${TMPDIR:-/tmp}/chart-checks"

swift build --package-path "$store" >/dev/null
triple="$(swift -print-target-info | sed -n 's/.*"unversionedTriple": "\([^"]*\)".*/\1/p')"
rulesDebug="$rules/.build/$triple/debug"
storeDebug="$store/.build/$triple/debug"

swiftc -swift-version 6 \
    -I "$storeDebug/Modules" -I "$rulesDebug/Modules" \
    "$storeDebug"/HoppaRules.build/*.o "$storeDebug"/HoppaStore.build/*.o \
    -o "$out" \
    "$here/../../Hoppa/Hoppa/LogbookLocation.swift" \
    "$here/../../Hoppa/Hoppa/HarnessSeed.swift" \
    "$here/main.swift"
"$out"
