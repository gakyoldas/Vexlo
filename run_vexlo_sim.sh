#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=Scripts/simulator.env
source "$ROOT_DIR/Scripts/simulator.env"

SIM_ID="$VEXLO_SIM_ID"
BUNDLE_ID="com.northfallstudio.Vexlo"

echo "Using simulator: $VEXLO_SIM_NAME ($SIM_ID)"

xcodebuild \
  -project Vexlo.xcodeproj \
  -scheme Vexlo \
  -destination "id=$SIM_ID" \
  -derivedDataPath .deriveddata \
  build

APP_PATH=$(find .deriveddata/Build/Products -name "Vexlo.app" | head -n 1)

if [ ! -d "$APP_PATH" ]; then
  echo "Built app not found."
  exit 1
fi

xcrun simctl install "$SIM_ID" "$APP_PATH"
xcrun simctl terminate "$SIM_ID" "$BUNDLE_ID" || true
xcrun simctl launch "$SIM_ID" "$BUNDLE_ID"
