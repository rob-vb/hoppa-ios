#!/usr/bin/env bash
# Ticket 0060 — the stack load line, walked on this machine.
#
# `DomainCopy.swift` lives in the app target but imports no SwiftUI, so it compiles here
# against the built `HoppaRules` (see the build map's charter bullet on Swift on the VPS).
# The view prints `StackLoad.loadLine` and decides nothing; this is that English, against
# the shipping solver.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
rules="$here/../../HoppaRules"
out="${TMPDIR:-/tmp}/load-line-checks"

swift build --package-path "$rules" >/dev/null
debug="$rules/.build/$(swift -print-target-info | sed -n 's/.*"unversionedTriple": "\([^"]*\)".*/\1/p')/debug"

swiftc -swift-version 6 \
    -I "$debug/Modules" "$debug"/HoppaRules.build/*.o \
    -o "$out" \
    "$here/../../Hoppa/Hoppa/DomainCopy.swift" "$here/main.swift"
"$out"
