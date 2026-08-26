#!/usr/bin/env bash
# Ticket 0043 — walk the Exercise sheet's unit stash on this machine.
#
# `UnitStash.swift` lives in the app target but imports no SwiftUI, so it compiles here
# against the built `HoppaRules` (see the build map's charter bullet on Swift on the VPS).
# This is the check ticket 0029's "no UI tests" rule leaves room for: the logic left the
# view, so it is provable off the Mac.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
rules="$here/../../HoppaRules"
out="${TMPDIR:-/tmp}/unit-stash-checks"

swift build --package-path "$rules" >/dev/null
debug="$rules/.build/$(swift -print-target-info | sed -n 's/.*"unversionedTriple": "\([^"]*\)".*/\1/p')/debug"

swiftc -swift-version 6 \
    -I "$debug/Modules" "$debug"/HoppaRules.build/*.o \
    -o "$out" \
    "$here/../../Hoppa/Hoppa/UnitStash.swift" "$here/main.swift"
"$out"
