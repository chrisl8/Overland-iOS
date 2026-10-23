#!/usr/bin/env bash
# Build a Release configuration and install it on a connected iPhone.
#
#   scripts/install-release.sh [device name or UDID]    (default: SonicScrewdriver)
#
# Run this from a Terminal window on the Mac's own desktop session. From tmux, ssh or an
# automated tool, codesign can't reach the signing key and fails with errSecInternalComponent.
# The phone must be unlocked and connected (or paired and on the same network).
#
# Needs developer_setup.xcconfig (TEAM_ID, BUNDLE_ID). With a paid team the development
# profile lasts about a year; with a free Apple ID it lasts 7 days.
set -euo pipefail
cd "$(dirname "$0")/.."

device="${1:-SonicScrewdriver}"
[ -f developer_setup.xcconfig ] || { echo "copy template_setup.xcconfig to developer_setup.xcconfig first" >&2; exit 1; }

dd=build/release-dd
echo "Building Release for $device"
xcodebuild build \
  -workspace Overland.xcworkspace \
  -scheme Overland \
  -configuration Release \
  -destination "platform=iOS,name=$device" \
  -derivedDataPath "$dd" \
  -allowProvisioningUpdates \
  OTHER_CODE_SIGN_FLAGS="--keychain $HOME/Library/Keychains/login.keychain-db"

echo "Installing on $device"
xcrun devicectl device install app --device "$device" "$dd/Build/Products/Release-iphoneos/Overland.app"
echo "Installed. Launch Overland on the phone."
