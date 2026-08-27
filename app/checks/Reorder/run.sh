#!/usr/bin/env bash
# Ticket 0044 — walk the reorder handle's arithmetic on this machine.
#
# `ReorderDrag.swift` lives in the app target but imports nothing, so it compiles here on
# its own (see the build map's charter bullet on Swift on the VPS). `ReorderColumn` is the
# SwiftUI around it and stays Mac-only; what is provable is the part that decides where a
# card lands, which is the part a hand-rolled drag gets wrong.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
out="${TMPDIR:-/tmp}/reorder-checks"

swiftc -swift-version 6 \
    -o "$out" \
    "$here/../../Hoppa/Hoppa/ReorderDrag.swift" "$here/main.swift"
"$out"
