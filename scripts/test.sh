#!/usr/bin/env bash
# Build and test script for PokéJournal Capture
# Usage: ./scripts/test.sh [build|test]
set -e

cd "$(dirname "$0")/.."

# Pick a simulator: latest iOS runtime, prefer booted to avoid spawning extras.
DEST=$(xcrun simctl list devices iPhone available -j 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
candidates = []
for runtime, devices in sorted(data.get('devices', {}).items()):
    if 'iOS' not in runtime: continue
    for d in devices:
        if not d.get('isAvailable'): continue
        candidates.append((runtime, d['state'] == 'Booted', d['udid']))
if not candidates: sys.exit(1)
candidates.sort(key=lambda x: (x[0], x[1]), reverse=True)
print(f'platform=iOS Simulator,id={candidates[0][2]}')
" 2>/dev/null) || DEST='platform=iOS Simulator,name=iPhone 17 Pro'

case "${1:-test}" in
    build)
        xcodebuild build \
          -project "PokeJournal Capture/PokeJournal Capture.xcodeproj" \
          -scheme "PokeJournal Capture" \
          -destination "$DEST"
        ;;
    test)
        xcodebuild test \
          -project "PokeJournal Capture/PokeJournal Capture.xcodeproj" \
          -scheme "PokeJournal Capture" \
          -destination "$DEST"
        ;;
    *)
        echo "Usage: $0 [build|test]"
        exit 1
        ;;
esac
