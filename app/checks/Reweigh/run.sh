#!/usr/bin/env bash
# Ticket 0046 — walk the Re-weigh list's screen logic on this machine.
#
# `ReweighScreen.swift` imports SwiftUI and cannot compile here, so `main.swift` carries a
# thin ring around it and compiles against the built `HoppaRules` (see the build map's
# charter bullet on Swift on the VPS). Every write in it goes through `Rules.reduce`, so
# the screen's one action is judged by the shipping rule and not by a copy of it.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
rules="$here/../../HoppaRules"
out="${TMPDIR:-/tmp}/reweigh-checks"

swift build --package-path "$rules" >/dev/null
debug="$rules/.build/$(swift -print-target-info | sed -n 's/.*"unversionedTriple": "\([^"]*\)".*/\1/p')/debug"

swiftc -swift-version 6 \
    -I "$debug/Modules" "$debug"/HoppaRules.build/*.o \
    -o "$out" \
    "$here/main.swift"
"$out"
