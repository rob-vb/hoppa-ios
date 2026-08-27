#!/usr/bin/env bash
# Ticket 0048 — walk the past-Workout screen's own logic on this machine.
#
# `PastWorkoutScreen.swift` imports SwiftUI, so it cannot be compiled here. `main.swift` is
# the thin ring around the parts of it that are not SwiftUI: the header's meta line, the
# verdict beside a name, the One-off chip, the weight text and the confirm's two sentences.
# **That ring is a copy and it can rot**; keep it in step by hand when the screen changes,
# and keep it as small as it is. Same bargain as `app/checks/History` and `app/checks/Reweigh`.
#
# `Rules.pastWorkout` is not copied — it is the shipping call, linked from the built
# package, with its own suite beside it. `HarnessSeed.swift` is not copied either: it
# imports no SwiftUI, so ticket 0047's sixteen-week seed is compiled and **run** here, and
# every one of its fifty-six Workouts is read back through the screen's own English.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
rules="$here/../../HoppaRules"
store="$here/../../HoppaStore"
out="${TMPDIR:-/tmp}/past-checks"

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
