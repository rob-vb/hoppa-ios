#!/usr/bin/env bash
# Ticket 0058 — walk the Progress page's own logic on this machine.
#
# `ProgressScreen.swift` imports SwiftUI, so it cannot be compiled here. `main.swift` is the
# thin ring around the parts of it that are not SwiftUI: the meta line, the green line, the
# empty copy, and the picker's Progress row. **That ring is a copy and it can rot**; keep it
# in step by hand when the screen changes, and keep it as small as it is. Same bargain as
# `app/checks/History`.
#
# The rule under it is not copied: `Rules.progress` is the shipping call, linked from the
# built package, with its own suite in `HoppaRulesTests`. `HarnessSeed.swift` is not copied
# either — it imports no SwiftUI, so the sixteen-week seed the phone gets is compiled and
# **run** here.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
rules="$here/../../HoppaRules"
store="$here/../../HoppaStore"
out="${TMPDIR:-/tmp}/progress-checks"

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
