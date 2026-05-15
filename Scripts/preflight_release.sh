#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

failures=0

pass() {
    printf '✓ %s\n' "$1"
}

fail() {
    printf '✗ %s\n' "$1" >&2
    failures=$((failures + 1))
}

require_file() {
    local path="$1"
    if [[ -e "$path" ]]; then
        pass "found $path"
    else
        fail "missing $path"
    fi
}

require_text() {
    local path="$1"
    local text="$2"
    local label="$3"
    if [[ -e "$path" ]] && /usr/bin/grep -Fq -- "$text" "$path"; then
        pass "$label"
    else
        fail "$label"
    fi
}

require_project_text() {
    local text="$1"
    local label="$2"
    require_text "Vexlo.xcodeproj/project.pbxproj" "$text" "$label"
}

echo "Vexlo release preflight"

require_file "Vexlo.xcodeproj/project.pbxproj"
require_project_text "Vexlo.app" "app product exists in project"
require_project_text "VexloWidgetExtension.appex" "widget extension product exists in project"

require_file "Vexlo/Vexlo.entitlements"
require_file "VexloWidget/VexloWidget.entitlements"
require_text "Vexlo/Vexlo.entitlements" "group.com.northfallstudio.Vexlo" "app App Group entitlement"
require_text "VexloWidget/VexloWidget.entitlements" "group.com.northfallstudio.Vexlo" "widget App Group entitlement"
require_text "Vexlo/Vexlo.entitlements" "com.apple.developer.ubiquity-kvstore-identifier" "app iCloud KVS entitlement"
require_text "Vexlo/Vexlo.entitlements" "com.apple.developer.game-center" "app Game Center entitlement"

require_file "VexloWidget/VexloWidget.swift"
require_file "VexloWidget/VexloWidgetBundle.swift"
require_file "Vexlo/VexloAppIntents.swift"
require_file "Vexlo/Services/ResultShareService.swift"

require_file "Vexlo/Services/LaunchSupport.swift"
require_text "Vexlo/Services/LaunchSupport.swift" "-VexloCaptureState" "hidden capture state argument"
require_text "Vexlo/Services/LaunchSupport.swift" "-VexloCaptureScore" "hidden capture score argument"
require_text "Vexlo/Services/LaunchSupport.swift" "-VexloCaptureIntent" "hidden capture intent argument"
require_text "Vexlo/Services/LaunchSupport.swift" "normal-result" "normal result capture state"
require_text "Vexlo/Services/LaunchSupport.swift" "daily-result" "daily result capture state"
require_text "Vexlo/Services/LaunchSupport.swift" "normal-hero" "normal hero capture state"
require_text "Vexlo/Services/LaunchSupport.swift" "daily-hero" "daily hero capture state"
require_text "Vexlo/Services/LaunchSupport.swift" "utility-surface" "utility surface capture state"

require_file "Vexlo/Services/DailyChallengeService.swift"
require_file "Vexlo/Services/GameCenterService.swift"
require_file "Vexlo/Services/ICloudProgressSyncService.swift"
require_file "Vexlo/Services/WidgetSurfaceService.swift"
require_file "Vexlo/Services/LiveRunPersistenceService.swift"
require_file "VexloTests/CriticalPathRegressionTests.swift"

if (( failures > 0 )); then
    printf '\nPreflight failed: %d issue(s).\n' "$failures" >&2
    exit 1
fi

echo "Preflight passed."
