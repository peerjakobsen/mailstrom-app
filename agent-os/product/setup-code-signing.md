# macOS Code Signing & Distribution Setup

## Prerequisites
- Apple Developer Program membership ($99/year): https://developer.apple.com/programs/
- Xcode installed with command line tools
- Valid Apple ID linked to developer account

## Step 1: Create Certificates

1. Open **Keychain Access** > Certificate Assistant > Request a Certificate from a Certificate Authority
2. Enter your email, select "Saved to disk"
3. Go to https://developer.apple.com/account/resources/certificates
4. Create two certificates:
   - **Developer ID Application** (for distributing outside App Store)
   - **Mac Development** (for local testing)
5. Download and double-click to install in Keychain

## Step 2: Create App ID

1. Go to https://developer.apple.com/account/resources/identifiers
2. Register new App ID:
   - Platform: macOS
   - Bundle ID: `com.mailstrom.app` (explicit)
   - Capabilities: N/A (no special entitlements needed beyond Keychain)

## Step 3: Create Provisioning Profile

1. Go to https://developer.apple.com/account/resources/profiles
2. Create **macOS App Development** profile:
   - Select the App ID created above
   - Select your Mac Development certificate
   - Select your device(s)
3. Download the `.provisionprofile` file
4. Double-click to install in Xcode

## Step 4: Configure Xcode Signing

1. Open `macos/Runner.xcworkspace` in Xcode
2. Select Runner target > Signing & Capabilities
3. Set Team to your Apple Developer team
4. Set Bundle Identifier to `com.mailstrom.app`
5. Select "Automatically manage signing" OR manually assign the provisioning profile
6. Ensure both Debug and Release schemes use the correct signing identity

## Step 5: Build Signed App

```bash
cd mailstrom
flutter build macos --release
```

The signed app will be at `build/macos/Build/Products/Release/Mailstrom.app`.

## Step 6: Notarize for Distribution

Notarization is required for apps distributed outside the Mac App Store.

```bash
# Create a ZIP for notarization
ditto -c -k --keepParent build/macos/Build/Products/Release/Mailstrom.app Mailstrom.zip

# Submit for notarization
xcrun notarytool submit Mailstrom.zip \
  --apple-id your@email.com \
  --team-id YOUR_TEAM_ID \
  --password @keychain:AC_PASSWORD \
  --wait

# Staple the notarization ticket
xcrun stapler staple build/macos/Build/Products/Release/Mailstrom.app
```

Note: Store your app-specific password in Keychain first:
```bash
xcrun notarytool store-credentials --apple-id your@email.com --team-id YOUR_TEAM_ID
```

## Step 7: Create DMG for Distribution

```bash
# Install create-dmg if needed
brew install create-dmg

# Create DMG
create-dmg \
  --volname "Mailstrom" \
  --window-pos 200 120 \
  --window-size 600 400 \
  --icon-size 100 \
  --icon "Mailstrom.app" 175 190 \
  --app-drop-link 425 190 \
  Mailstrom.dmg \
  build/macos/Build/Products/Release/Mailstrom.app
```

## Keychain Access

The app uses `flutter_secure_storage` which requires Keychain access. The entitlements files already include `keychain-access-groups` with `$(AppIdentifierPrefix)com.mailstrom.app`. This works automatically when the app is code-signed with a valid certificate.

For unsigned development builds, Keychain access may fail silently. Use the Debug scheme with your Mac Development certificate.

## Troubleshooting

- **"Mailstrom can't be opened"**: App not signed or notarized. Right-click > Open to bypass Gatekeeper once.
- **Keychain access denied**: Check entitlements match the provisioning profile's App ID.
- **Notarization fails**: Ensure hardened runtime is enabled and no disallowed entitlements are present.
