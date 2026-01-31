# Google Cloud OAuth Setup

This guide walks through setting up a Google Cloud project with OAuth credentials for the Gmail API. The app will run in "Testing" mode, allowing you and up to 100 test users to authenticate without Google verification.

## Prerequisites

- A Google account (personal Gmail works fine)
- Access to [Google Cloud Console](https://console.cloud.google.com)

## Step 1: Create a Google Cloud Project

1. Go to [console.cloud.google.com](https://console.cloud.google.com)
2. Click the project dropdown in the top-left → **New Project**
3. Project name: `Mailstrom`
4. Organization: leave as-is (or "No organization")
5. Click **Create**
6. Wait for creation, then select the project from the dropdown

## Step 2: Enable the Gmail API

1. In the left sidebar, go to **APIs & Services** → **Library**
2. Search for `Gmail API`
3. Click on **Gmail API** in the results
4. Click **Enable**
5. Wait for it to enable (takes a few seconds)

## Step 3: Configure OAuth Consent Screen

1. Go to **APIs & Services** → **OAuth consent screen**
2. Select **External** → Click **Create**
3. Fill in the **App information**:
   - App name: `Mailstrom`
   - User support email: *your email*
   - App logo: skip for now
4. **App domain**: leave all blank (not required for testing)
5. **Developer contact information**: *your email*
6. Click **Save and Continue**

### Add Scopes

1. Click **Add or Remove Scopes**
2. In the filter box, search for `gmail`
3. Check these two scopes:
   - `https://www.googleapis.com/auth/gmail.readonly`
   - `https://www.googleapis.com/auth/gmail.modify`
4. Click **Update**
5. Click **Save and Continue**

### Add Test Users

1. Click **+ Add Users**
2. Add your email (e.g., `peer.jakobsen@gmail.com`)
3. Add any other emails you want to test with (up to 100)
4. Click **Add**
5. Click **Save and Continue**
6. Review the summary → Click **Back to Dashboard**

## Step 4: Create OAuth Client ID

1. Go to **APIs & Services** → **Credentials**
2. Click **+ Create Credentials** → **OAuth client ID**
3. Application type: **Desktop app**
4. Name: `Mailstrom macOS`
5. Click **Create**
6. A dialog appears with your Client ID and Client Secret
7. Click **Download JSON**
8. Save the file as `google_oauth_credentials.json`

## Step 5: Add Credentials to the Project

1. Move `google_oauth_credentials.json` to your project root (or a `secrets/` folder)
2. **Important**: Add it to `.gitignore` to avoid committing secrets:
   ```
   # .gitignore
   google_oauth_credentials.json
   secrets/
   ```

The JSON file contains:
```json
{
  "installed": {
    "client_id": "xxxx.apps.googleusercontent.com",
    "client_secret": "GOCSPX-xxxx",
    "auth_uri": "https://accounts.google.com/o/oauth2/auth",
    "token_uri": "https://oauth2.googleapis.com/token",
    "redirect_uris": ["http://localhost"]
  }
}
```

## Step 6: Usage in Flutter

**Use the JSON file directly — not a `.env` file.**

The `googleapis_auth` package expects Google's JSON credential format and can read it natively. This is simpler than parsing a `.env` file and is the standard approach for Google APIs.

```dart
// Load credentials from JSON file
final credentialsFile = File('google_oauth_credentials.json');
final credentials = json.decode(await credentialsFile.readAsString());
final clientId = ClientId(
  credentials['installed']['client_id'],
  credentials['installed']['client_secret'],
);
```

The `googleapis_auth` package handles the desktop OAuth flow, opening a browser for consent and capturing the redirect.

## Notes

- **Testing mode**: Only users you explicitly added as test users can authenticate. This is fine for personal use.
- **Unverified app warning**: Users will see a "Google hasn't verified this app" screen during login. Click "Advanced" → "Go to Mailstrom (unsafe)" to proceed. This is normal for testing.
- **Publishing later**: If you want to ship publicly, you'll need to submit for Google verification (requires privacy policy, homepage, and security review for sensitive scopes).
- **Token refresh**: OAuth tokens expire. The app stores the refresh token in macOS Keychain and automatically refreshes access tokens.

## Quota Limits (Free Tier)

- Daily quota: 1,000,000,000 units (very generous)
- `messages.list`: 5 units per request
- `messages.get`: 5 units per request
- Batch requests: up to 100 per batch

For a personal inbox cleanup tool, you'll never hit these limits.
