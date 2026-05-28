#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=simulator.env
source "$ROOT_DIR/Scripts/simulator.env"

cd "$ROOT_DIR"

DESTINATION="platform=iOS Simulator,id=$VEXLO_SIM_ID"
echo "Testing on $VEXLO_SIM_NAME ($VEXLO_SIM_ID)"

if [[ $# -gt 0 ]]; then
  xcodebuild -scheme Vexlo -destination "$DESTINATION" "$@"
else
  xcodebuild -scheme Vexlo -destination "$DESTINATION" test
fi
