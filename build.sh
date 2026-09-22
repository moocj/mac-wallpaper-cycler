#!/bin/bash
# Builds "Wallpaper Cycler.app" from the swift package, so it can be
# double-clicked and moved to /Applications.
# Needs the Xcode command line tools:  xcode-select --install
set -euo pipefail
cd "$(dirname "$0")"

APP="Wallpaper Cycler.app"
VERSION="0.1.0"
BUILD="1"

if ! command -v swift >/dev/null 2>&1; then
  echo "swift not found — install the command line tools:  xcode-select --install"
  exit 1
fi

echo "Building (release)..."
swift build -c release

BIN_DIR="$(swift build -c release --show-bin-path)"
BIN="$BIN_DIR/WallpaperCycler"
if [ ! -f "$BIN" ]; then
  echo "Build output not found at $BIN"
  exit 1
fi

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/WallpaperCycler"

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key><string>WallpaperCycler</string>
  <key>CFBundleIdentifier</key><string>com.moocj.wallpapercycler</string>
  <key>CFBundleName</key><string>Wallpaper Cycler</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>${VERSION}</string>
  <key>CFBundleVersion</key><string>${BUILD}</string>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
  <key>LSUIElement</key><true/>
  <key>NSHighResolutionCapable</key><true/>
  <key>NSPrincipalClass</key><string>NSApplication</string>
</dict>
</plist>
PLIST

# ad-hoc signature, which is all a locally built app needs to run
codesign --force --sign - "$APP" >/dev/null

echo ""
echo "Built: $(pwd)/$APP"
echo "Run:   open \"$APP\""
echo "Tip:   move it to /Applications for launch at login."