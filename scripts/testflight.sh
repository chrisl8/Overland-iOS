#!/usr/bin/env bash
# Archive a Release build and upload it to TestFlight.
#
#   ASC_ISSUER_ID=<uuid> scripts/testflight.sh
#
# Needs developer_setup.xcconfig (TEAM_ID, BUNDLE_ID) and an App Store Connect API key at
# ~/.appstoreconnect/private_keys/AuthKey_<ASC_KEY_ID>.p8. The app record for BUNDLE_ID
# must already exist in App Store Connect.
set -euo pipefail
cd "$(dirname "$0")/.."

: "${ASC_ISSUER_ID:?set ASC_ISSUER_ID (App Store Connect > Users and Access > Integrations)}"
ASC_KEY_ID="${ASC_KEY_ID:-96B3KLFU82}"
KEY_PATH="${ASC_KEY_PATH:-$HOME/.appstoreconnect/private_keys/AuthKey_${ASC_KEY_ID}.p8}"
[ -f "$KEY_PATH" ] || { echo "no API key at $KEY_PATH" >&2; exit 1; }
[ -f developer_setup.xcconfig ] || { echo "copy template_setup.xcconfig to developer_setup.xcconfig first" >&2; exit 1; }

team=$(sed -n 's/^TEAM_ID *= *//p' developer_setup.xcconfig)
# Every upload needs a higher build number than the last, so use the time.
build=$(date +%Y%m%d%H%M)
out=build
auth=(-allowProvisioningUpdates
      -authenticationKeyPath "$KEY_PATH"
      -authenticationKeyID "$ASC_KEY_ID"
      -authenticationKeyIssuerID "$ASC_ISSUER_ID")

rm -rf "$out"
mkdir -p "$out"
cat > "$out/ExportOptions.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>method</key><string>app-store-connect</string>
	<key>destination</key><string>upload</string>
	<key>teamID</key><string>$team</string>
	<key>signingStyle</key><string>automatic</string>
	<key>uploadSymbols</key><true/>
</dict>
</plist>
PLIST

echo "Archiving build $build"
xcodebuild archive \
  -workspace Overland.xcworkspace \
  -scheme Overland \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath "$out/Overland.xcarchive" \
  CURRENT_PROJECT_VERSION="$build" \
  "${auth[@]}"

echo "Exporting and uploading to TestFlight"
xcodebuild -exportArchive \
  -archivePath "$out/Overland.xcarchive" \
  -exportOptionsPlist "$out/ExportOptions.plist" \
  -exportPath "$out/export" \
  "${auth[@]}"

echo "Uploaded build $build. It appears in TestFlight after Apple finishes processing it."
