#!/bin/bash
set -euo pipefail

# Write Diary AI — iOS Build & Upload Script
# Usage: ./build-ipa.sh [--upload]
#   --upload   Upload the resulting IPA to TestFlight via fastlane
# Requires: fastlane (brew install fastlane), Flutter, Xcode, Apple Distribution cert in Keychain
#
# Before first run: authenticate fastlane with App Store Connect credentials.
# Simplest: export an App Store Connect API key (recommended):
#   export APP_STORE_CONNECT_API_KEY_KEY_ID="XXXXXXXXXX"
#   export APP_STORE_CONNECT_API_KEY_ISSUER_ID="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
#   export APP_STORE_CONNECT_API_KEY_KEY_FILEPATH="$HOME/.private_keys/AuthKey_XXXXXXXXXX.p8"
# OR set FASTLANE_USER / FASTLANE_PASSWORD (and FASTLANE_SESSION for 2FA).

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
FRONTEND_DIR="$PROJECT_DIR/frontend"
IOS_DIR="$FRONTEND_DIR/ios"
EXPORT_DIR="$HOME/Desktop/南木潤/WriteDiaryAIExport"
ARCHIVE_PATH="$EXPORT_DIR/WriteDiaryAI.xcarchive"
EXPORT_OPTIONS="$EXPORT_DIR/ExportOptions.plist"
IPA_NAME="write_diary_ai.ipa"
TEAM_ID="CQ45UMBK28"
BUNDLE_ID="com.writediaryai.writeDiaryAi"
SCHEME="Runner"

UPLOAD=false
if [ "${1:-}" = "--upload" ]; then
  UPLOAD=true
fi

mkdir -p "$EXPORT_DIR"

echo "================================================"
echo "  Write Diary AI — iOS Build"
echo "  Bundle ID : $BUNDLE_ID"
echo "  Team ID   : $TEAM_ID"
echo "  Export    : $EXPORT_DIR"
echo "================================================"

# ---------------------------------------------------------------------------
# Pre-flight: confirm fastlane can authenticate with Apple Developer.
# ---------------------------------------------------------------------------
if [ -n "${APP_STORE_CONNECT_API_KEY_KEY_ID:-}" ] \
   && [ -n "${APP_STORE_CONNECT_API_KEY_ISSUER_ID:-}" ] \
   && [ -n "${APP_STORE_CONNECT_API_KEY_KEY_FILEPATH:-}" ]; then
  echo "[auth] Using App Store Connect API key ${APP_STORE_CONNECT_API_KEY_KEY_ID}"
elif [ -n "${FASTLANE_USER:-}" ]; then
  echo "[auth] Using Apple ID: $FASTLANE_USER"
  if [ -z "${FASTLANE_PASSWORD:-}" ] && [ -z "${FASTLANE_SESSION:-}" ]; then
    echo "[auth] WARNING: FASTLANE_USER is set but neither FASTLANE_PASSWORD"
    echo "       nor FASTLANE_SESSION is set. fastlane may prompt interactively."
  fi
else
  cat <<'AUTH_HELP'

ERROR: No Apple Developer credentials detected for fastlane.

Pick ONE of the following auth methods and re-run:

1) App Store Connect API key (recommended, non-interactive, 2FA-friendly):
     Create a key at https://appstoreconnect.apple.com/access/api and:
       export APP_STORE_CONNECT_API_KEY_KEY_ID="XXXXXXXXXX"
       export APP_STORE_CONNECT_API_KEY_ISSUER_ID="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
       export APP_STORE_CONNECT_API_KEY_KEY_FILEPATH="$HOME/.private_keys/AuthKey_XXXXXXXXXX.p8"

2) Apple ID + app-specific password:
       export FASTLANE_USER="you@example.com"
       export FASTLANE_PASSWORD="app-specific-password-from-appleid.apple.com"
     For 2FA accounts you may also need FASTLANE_SESSION — generate via:
       fastlane spaceauth -u you@example.com

AUTH_HELP
  exit 1
fi


# ---------------------------------------------------------------------------
# Step 1: Ensure distribution certificate + App Store provisioning profile.
# ---------------------------------------------------------------------------
echo ""
echo "[1/5] Ensuring Apple Distribution certificate & App Store profile..."
cd "$IOS_DIR"

# Fetch/create Apple Distribution certificate for this team.
fastlane run get_certificates \
  development:false \
  team_id:"$TEAM_ID" \
  output_path:"$EXPORT_DIR/certs" \
  generate_apple_certs:true

# Fetch/create the App Store provisioning profile for the bundle id.
fastlane run get_provisioning_profile \
  app_identifier:"$BUNDLE_ID" \
  team_id:"$TEAM_ID" \
  output_path:"$EXPORT_DIR/profiles" \
  filename:"WriteDiaryAI_AppStore.mobileprovision"

PROFILE_PATH=$(ls -t "$EXPORT_DIR/profiles/"*.mobileprovision 2>/dev/null | head -1)
if [ -z "$PROFILE_PATH" ]; then
  echo "ERROR: No provisioning profile found at $EXPORT_DIR/profiles/"
  exit 1
fi

# Install the profile so Xcode can discover it during archive.
PROFILE_UUID=$(security cms -D -i "$PROFILE_PATH" 2>/dev/null | plutil -extract UUID raw - || true)
if [ -z "$PROFILE_UUID" ]; then
  # Fallback to grep if plutil/cms path not available
  PROFILE_UUID=$(grep -aA1 UUID "$PROFILE_PATH" | grep -o '[-A-Fa-f0-9]\{36\}' | head -1)
fi
PROFILE_NAME=$(security cms -D -i "$PROFILE_PATH" 2>/dev/null | plutil -extract Name raw - || true)
mkdir -p "$HOME/Library/MobileDevice/Provisioning Profiles"
cp "$PROFILE_PATH" "$HOME/Library/MobileDevice/Provisioning Profiles/${PROFILE_UUID}.mobileprovision"

echo "  Profile: $(basename "$PROFILE_PATH")"
echo "  Name   : $PROFILE_NAME"
echo "  UUID   : $PROFILE_UUID"

# ---------------------------------------------------------------------------
# Step 2: Flutter pub get + generate iOS build artifacts (Pods, Flutter.xcframework).
# ---------------------------------------------------------------------------
echo ""
echo "[2/5] Preparing Flutter iOS build artifacts..."
cd "$FRONTEND_DIR"
flutter pub get
# Build once without codesigning to make sure Pods/Flutter.xcframework are in place.
flutter build ios --release --no-codesign | tail -5

# Re-run `pod install` after flutter build to make sure Podfile post_install
# hooks (which strip signing from pod targets) are applied to the Pods project.
cd "$IOS_DIR"
pod install --silent | tail -5 || pod install | tail -10

# ---------------------------------------------------------------------------
# Step 3: Archive via xcodebuild using the Flutter-generated workspace.
# ---------------------------------------------------------------------------
echo ""
echo "[3/5] Archiving (xcodebuild)..."
rm -rf "$ARCHIVE_PATH"
cd "$IOS_DIR"
ARCHIVE_LOG="$EXPORT_DIR/xcodebuild-archive.log"
set +e
xcodebuild clean archive \
  -workspace Runner.xcworkspace \
  -scheme "$SCHEME" \
  -configuration Release \
  -archivePath "$ARCHIVE_PATH" \
  -destination "generic/platform=iOS" \
  CODE_SIGN_STYLE=Manual \
  DEVELOPMENT_TEAM="$TEAM_ID" \
  PROVISIONING_PROFILE_SPECIFIER="$PROFILE_NAME" \
  CODE_SIGN_IDENTITY="Apple Distribution" \
  -allowProvisioningUpdates \
  2>&1 | tee "$ARCHIVE_LOG" | tail -20
ARCHIVE_EXIT=${PIPESTATUS[0]}
set -e

if [ "$ARCHIVE_EXIT" -ne 0 ] || [ ! -d "$ARCHIVE_PATH" ]; then
  echo ""
  echo "ERROR: Archive step failed (exit $ARCHIVE_EXIT). Last 40 log lines:"
  tail -40 "$ARCHIVE_LOG" || true
  echo ""
  echo "Full log: $ARCHIVE_LOG"
  exit 1
fi

echo "  Archive: $ARCHIVE_PATH"

# ---------------------------------------------------------------------------
# Step 4: Export IPA.
# ---------------------------------------------------------------------------
echo ""
echo "[4/5] Exporting IPA..."

cat > "$EXPORT_OPTIONS" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>method</key>
	<string>app-store-connect</string>
	<key>teamID</key>
	<string>${TEAM_ID}</string>
	<key>signingStyle</key>
	<string>manual</string>
	<key>signingCertificate</key>
	<string>Apple Distribution</string>
	<key>provisioningProfiles</key>
	<dict>
		<key>${BUNDLE_ID}</key>
		<string>${PROFILE_NAME}</string>
	</dict>
	<key>uploadBitcode</key>
	<false/>
	<key>uploadSymbols</key>
	<true/>
	<key>destination</key>
	<string>export</string>
</dict>
</plist>
EOF

# Clean old export
rm -f "$EXPORT_DIR/$IPA_NAME" "$EXPORT_DIR/DistributionSummary.plist" "$EXPORT_DIR/Packaging.log" "$EXPORT_DIR/ExportOptions-Result.plist"
# Remove any stale *.ipa left behind from a previous export
find "$EXPORT_DIR" -maxdepth 1 -name "*.ipa" -delete 2>/dev/null || true

xcodebuild -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_DIR" \
  -exportOptionsPlist "$EXPORT_OPTIONS" \
  -allowProvisioningUpdates \
  2>&1 | tee "$EXPORT_DIR/xcodebuild-export.log" | tail -20

# xcodebuild names the ipa after the scheme or app display name
# (Runner.ipa, "Write Diary AI.ipa", etc.). Rename the first one we find.
PRODUCED_IPA=$(find "$EXPORT_DIR" -maxdepth 1 -name "*.ipa" -type f | head -n 1)
if [ -n "$PRODUCED_IPA" ] && [ "$PRODUCED_IPA" != "$EXPORT_DIR/$IPA_NAME" ]; then
  mv "$PRODUCED_IPA" "$EXPORT_DIR/$IPA_NAME"
fi

if [ ! -f "$EXPORT_DIR/$IPA_NAME" ]; then
  echo "ERROR: IPA not produced. Check logs in $EXPORT_DIR."
  exit 1
fi

echo "  IPA: $EXPORT_DIR/$IPA_NAME"

# ---------------------------------------------------------------------------
# Step 5 (optional): Upload to TestFlight.
# ---------------------------------------------------------------------------
if [ "$UPLOAD" = true ]; then
  echo ""
  echo "[5/5] Uploading to App Store Connect (TestFlight)..."
  cd "$IOS_DIR"

  # `fastlane run <action>` does NOT auto-read APP_STORE_CONNECT_API_KEY_*
  # env vars the way a Fastfile lane does. We write a JSON key file and pass
  # it explicitly via api_key_path so altool gets proper JWT auth.
  UPLOAD_ARGS=(ipa:"$EXPORT_DIR/$IPA_NAME"
               team_id:"$TEAM_ID"
               skip_waiting_for_build_processing:true)

  if [ -n "${APP_STORE_CONNECT_API_KEY_KEY_ID:-}" ] \
     && [ -n "${APP_STORE_CONNECT_API_KEY_ISSUER_ID:-}" ] \
     && [ -n "${APP_STORE_CONNECT_API_KEY_KEY_FILEPATH:-}" ]; then
    API_KEY_JSON="$EXPORT_DIR/appstore_api_key.json"
    # key_content must be the p8 contents as a single string (with \n).
    P8_ESCAPED=$(awk '{printf "%s\\n", $0}' "$APP_STORE_CONNECT_API_KEY_KEY_FILEPATH")
    cat > "$API_KEY_JSON" <<EOF
{
  "key_id": "$APP_STORE_CONNECT_API_KEY_KEY_ID",
  "issuer_id": "$APP_STORE_CONNECT_API_KEY_ISSUER_ID",
  "key": "$P8_ESCAPED",
  "in_house": false
}
EOF
    chmod 600 "$API_KEY_JSON"
    UPLOAD_ARGS+=(api_key_path:"$API_KEY_JSON")
    echo "[auth] Using App Store Connect API key $APP_STORE_CONNECT_API_KEY_KEY_ID"
  fi

  fastlane run upload_to_testflight "${UPLOAD_ARGS[@]}" || UPLOAD_STATUS=$?
  UPLOAD_STATUS=${UPLOAD_STATUS:-0}

  # Remove the temporary key file — it contains the private key.
  [ -n "${API_KEY_JSON:-}" ] && rm -f "$API_KEY_JSON"

  if [ $UPLOAD_STATUS -ne 0 ]; then
    echo "ERROR: upload_to_testflight exited with status $UPLOAD_STATUS"
    exit $UPLOAD_STATUS
  fi

  echo ""
  echo "================================================"
  echo "  Done. Build uploaded to App Store Connect."
  echo "  Status: https://appstoreconnect.apple.com"
  echo "================================================"
else
  echo ""
  echo "================================================"
  echo "  Done. IPA ready at:"
  echo "    $EXPORT_DIR/$IPA_NAME"
  echo ""
  echo "  To upload to TestFlight, re-run with:"
  echo "    ./build-ipa.sh --upload"
  echo "  or use Transporter / Xcode Organizer."
  echo "================================================"
fi
