#!/bin/zsh
set -euo pipefail

ROOT_DIR="${0:A:h}"
APP_DIR="$ROOT_DIR/dist/LyricsBar.app"
MACOS_DIR="$APP_DIR/Contents/MacOS"

mkdir -p "$MACOS_DIR"
clang "$ROOT_DIR/Sources/LyricsBar/main.m" \
  -o "$MACOS_DIR/LyricsBar" \
  -arch arm64 \
  -arch x86_64 \
  -mmacosx-version-min=12.0 \
  -fobjc-arc -fblocks \
  -framework AppKit \
  -framework Foundation

/usr/libexec/PlistBuddy -c Clear "$APP_DIR/Contents/Info.plist" 2>/dev/null || true
/usr/libexec/PlistBuddy -c 'Add :CFBundleName string LyricsBar' "$APP_DIR/Contents/Info.plist"
/usr/libexec/PlistBuddy -c 'Add :CFBundleDisplayName string LyricsBar' "$APP_DIR/Contents/Info.plist"
/usr/libexec/PlistBuddy -c 'Add :CFBundleIdentifier string local.lyricsbar.app' "$APP_DIR/Contents/Info.plist"
/usr/libexec/PlistBuddy -c 'Add :CFBundleExecutable string LyricsBar' "$APP_DIR/Contents/Info.plist"
/usr/libexec/PlistBuddy -c 'Add :CFBundlePackageType string APPL' "$APP_DIR/Contents/Info.plist"
/usr/libexec/PlistBuddy -c 'Add :CFBundleShortVersionString string 1.0' "$APP_DIR/Contents/Info.plist"
/usr/libexec/PlistBuddy -c 'Add :LSUIElement bool true' "$APP_DIR/Contents/Info.plist"
/usr/libexec/PlistBuddy -c 'Add :NSAppleEventsUsageDescription string LyricsBar needs the current Apple Music track and playback position to synchronize lyrics.' "$APP_DIR/Contents/Info.plist"

codesign --force --deep --sign - "$APP_DIR"
echo "$APP_DIR"
