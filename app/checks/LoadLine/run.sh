#!/usr/bin/env bash
# Ticket 0060 — the stack load line, walked on this machine.
#
# Copy lives on `Phrasebook`. The solve is `Rules.breakdown`, the shipping call.
# What this proves is the English the logging screen prints for a pin, against
# the same remainder the drawing hangs.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
rules="$here/../../HoppaRules"
store="$here/../../HoppaStore"
out="${TMPDIR:-/tmp}/load-line-checks"

swift build --package-path "$store" >/dev/null
triple="$(swift -print-target-info | sed -n 's/.*"unversionedTriple": "\([^"]*\)".*/\1/p')"
rulesDebug="$rules/.build/$triple/debug"
storeDebug="$store/.build/$triple/debug"

swiftc -swift-version 6 \
    -I "$storeDebug/Modules" -I "$rulesDebug/Modules" \
    "$storeDebug"/HoppaRules.build/*.o "$storeDebug"/HoppaStore.build/*.o \
    -o "$out" \
    "$here/main.swift"
"$out"
