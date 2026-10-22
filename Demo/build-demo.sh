#!/usr/bin/env bash
# Builds and runs the UIKit demo in the iOS Simulator without an Xcode project:
#   Demo/build-demo.sh ["iPhone 16 Pro"]
set -euo pipefail
cd "$(dirname "$0")/.."
DEVICE="${1:-iPhone 16 Pro}"
OUT="${OUT:-build}"
APP="$OUT/CameraSelectMessageDemo.app"
SDK="$(xcrun --sdk iphonesimulator --show-sdk-path)"
ARCH="$(uname -m)"
rm -rf "$APP" && mkdir -p "$APP"

xcrun -sdk iphonesimulator swiftc -O -parse-as-library \
  -module-name CameraSelectMessageDemo \
  -target "$ARCH-apple-ios17.0-simulator" \
  -sdk "$SDK" \
  CameraSelectMessage/Sources/CameraSelectConfig.swift \
  CameraSelectMessage/Sources/CameraSelectGesture.swift \
  CameraSelectMessage/Sources/CameraSelectButtons.swift \
  CameraSelectMessage/Sources/CameraSelectController.swift \
  CameraSelectMessage/Sources/CameraSelectRecorder.swift \
  Demo/DemoViewController.swift \
  -framework AVFoundation -framework UIKit \
  -o "$APP/CameraSelectMessageDemo"

cp CameraSelectMessage/Resources/CameraSelectButtons.png "$APP/" 2>/dev/null || true

cat > "$APP/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleIdentifier</key>
  <string>demo.cameraselectmessage.kit</string>
  <key>CFBundleExecutable</key>
  <string>CameraSelectMessageDemo</string>
  <key>CFBundleName</key>
  <string>CameraSelect</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>1.0</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>MinimumOSVersion</key>
  <string>17.0</string>
  <key>UIDeviceFamily</key>
  <array><integer>1</integer></array>
  <key>UILaunchScreen</key>
  <dict/>
  <key>NSCameraUsageDescription</key>
  <string>Record video notes with front or main camera.</string>
  <key>NSMicrophoneUsageDescription</key>
  <string>Record audio for video notes.</string>
  <key>UIApplicationSceneManifest</key>
  <dict>
    <key>UIApplicationSupportsMultipleScenes</key>
    <false/>
  </dict>
  <key>CFBundleSupportedPlatforms</key>
  <array><string>iPhoneSimulator</string></array>
</dict>
</plist>
PLIST

codesign --force --sign - "$APP" >/dev/null
xcrun simctl boot "$DEVICE" 2>/dev/null || true
xcrun simctl install "$DEVICE" "$APP"
xcrun simctl launch --terminate-running-process "$DEVICE" demo.cameraselectmessage.kit
