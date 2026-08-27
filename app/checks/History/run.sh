#!/usr/bin/env bash
# Ticket 0047 — walk the history screen's own logic on this machine.
#
# `HistoryScreen.swift` imports SwiftUI, so it cannot be compiled here. `main.swift` is the
# thin ring around the parts of it that are not SwiftUI: the meta line, the picker's
# History row, and the dates. **That ring is a copy and it can rot**; keep it in step by
# hand when the screen changes, and keep it as small as it is. Same bargain as
# `app/checks/Reweigh`.
#
# The rules under it are not copied: `Rules.history` and `Streak.read` are the shipping
# calls, linked from the built packages. `HarnessSeed.swift` is not copied either — it
# imports no SwiftUI, so ticket 0047's sixteen-week seed is compiled and **run** here, the
# same bargain `app/checks/UnitStash` struck with `UnitStash.swift`.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
rules="$here/../../HoppaRules"
store="$here/../../HoppaStore"
out="${TMPDIR:-/tmp}/history-checks"

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
