#!/usr/bin/env bash
# Ticket 0052 — the two checks the app target can still get on this machine.
#
# Every other file in this app is either a rule or a store, and both compile here. The
# app target is SwiftUI, and SwiftUI does not exist on Linux, so `swiftc -typecheck` can
# never run over these files — which is why ticket 0029 wrote "no UI tests" and left the
# view layer's proof to Rob's eyes.
#
# Two things are provable here anyway, and the first one broke the build at item 1 of the
# walk:
#
#   1. **Two files must not declare the same top-level name.** Xcode compiles the target
#      as one module, so `PlateChip` in two files is `Invalid redeclaration of` — and
#      every call site of it becomes a second error, in a third file. No session that
#      writes one screen can see this; only a scan across the whole target can.
#   2. **Every file must parse.** `swiftc -parse` is purely syntactic, so it needs no
#      SwiftUI. It will not catch a type error, but it catches a file that cannot be read
#      at all before the Mac spends a build on it.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
target="$here/../../Hoppa/Hoppa"
failed=0

cd "$target"

# --- 1. Top-level names, across every file in the module ---------------------
#
# Column 0 is the module scope: anything indented is nested and cannot collide. An
# `extension` is not itself a name, so its members are keyed by the type they extend —
# `Color.floor` — which is the name that actually collides.
names="$(
    for file in *.swift; do
        awk -v file="$file" '
            /^(public |private |fileprivate |internal )?(final )?(struct|class|enum|actor|protocol|typealias) [A-Za-z0-9_]+/ {
                name = $0
                sub(/^(public |private |fileprivate |internal )?(final )?(struct|class|enum|actor|protocol|typealias) /, "", name)
                sub(/[^A-Za-z0-9_].*$/, "", name)
                print name, file
                next
            }
            /^(public |private |fileprivate |internal )?(func|var|let) [A-Za-z0-9_]+/ {
                name = $0
                sub(/^(public |private |fileprivate |internal )?(func|var|let) /, "", name)
                sub(/[^A-Za-z0-9_].*$/, "", name)
                print name, file
                next
            }
            /^extension [A-Za-z0-9_.]+/ { extended = $2; sub(/[^A-Za-z0-9_.].*$/, "", extended); next }
            /^}/ { extended = "" ; next }
            extended != "" && /^    (public |private |fileprivate |internal )?(static )?(func|var|let) [A-Za-z0-9_]+/ {
                name = $0
                sub(/^    (public |private |fileprivate |internal )?(static )?(func|var|let) /, "", name)
                sub(/[^A-Za-z0-9_].*$/, "", name)
                print extended "." name, file
            }
        ' "$file"
    done
)"

# A name is a clash only when two *different* files carry it. One file may overload a
# name freely — that is Swift, not a mistake — so the file column is what is counted.
clashes="$(printf '%s\n' "$names" | sort -u | awk '{print $1}' | uniq -d)"
if [ -n "$clashes" ]; then
    echo "FAIL — the same top-level name is declared in more than one file:"
    while read -r clash; do
        [ -z "$clash" ] && continue
        echo "  $clash"
        printf '%s\n' "$names" | awk -v c="$clash" '$1 == c { print "      " $2 }' | sort -u
    done <<< "$clashes"
    echo "  Xcode builds this target as one module, so each of these is a redeclaration."
    failed=1
else
    count="$(printf '%s\n' "$names" | sort -u | wc -l)"
    echo "ok — $count top-level names across $(ls -1 *.swift | wc -l) files, none declared twice"
fi

# --- 2. Every file parses ----------------------------------------------------
if swiftc -parse -swift-version 6 *.swift 2>/tmp/hoppa-parse.log; then
    echo "ok — every file in the app target parses"
else
    echo "FAIL — the app target does not parse:"
    cat /tmp/hoppa-parse.log
    failed=1
fi

exit "$failed"
