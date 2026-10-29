#!/bin/bash
set -euo pipefail

task_root="$(cd "$(dirname "$0")/../.." && pwd)"
task_derived="${1:-${TMPDIR:-/tmp}/mmf-forwarded-buttons-build}"
task_output="$(mktemp -d "${TMPDIR:-/tmp}/mmf-forwarded-buttons.XXXXXX")"
task_arch="$(uname -m)"

xcodebuild -project "$task_root/Mouse Fix.xcodeproj" -scheme 'Helper - Direct' \
    -configuration Debug -derivedDataPath "$task_derived" \
    CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO \
    ARCHS="$task_arch" ONLY_ACTIVE_ARCH=YES build > "$task_output/build.log" 2>&1

task_objects="$task_derived/Build/Intermediates.noindex/Mouse Fix.build/Debug/Mac Mouse Fix Helper.build/Objects-normal/$task_arch"

xcrun clang -fobjc-arc -Wall -Wextra -Werror \
    -I "$task_root/Shared/Devices" \
    "$task_root/Tests/ForwardedButtons/DeviceIdentityTests.m" "$task_objects/Device.o" \
    -framework Foundation -framework IOKit -o "$task_output/device-identity"
"$task_output/device-identity"

xcrun swiftc -swift-version 5 -warnings-as-errors \
    -import-objc-header "$task_root/Shared/Devices/Device.h" \
    "$task_root/Helper/Core/Buttons/ClickCycle.swift" \
    "$task_root/Tests/ForwardedButtons/TestSupport.swift" \
    "$task_root/Tests/ForwardedButtons/ClickCycleTests.swift" "$task_objects/Device.o" \
    -framework Cocoa -framework IOKit -o "$task_output/click-cycle"
"$task_output/click-cycle"

printf 'Test artifacts: %s\n' "$task_output"
