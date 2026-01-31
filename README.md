![Platform: macOS](https://img.shields.io/badge/platform-macOS-lightgrey)
![License: MIT](https://img.shields.io/badge/license-MIT-blue)
![Status: In Development](https://img.shields.io/badge/status-in%20development-orange)
[![Website](https://img.shields.io/badge/website-mailstrom.mentilead.com-blue)](https://mailstrom.mentilead.com)

# Mailstrom

Bulk-clean your Gmail inbox by sender — see who's flooding you, unsubscribe, and delete in one click.

## Features

- **Sender tree view** — Emails grouped by domain and sender with counts
- **Bulk delete** — Select senders and trash all their emails at once
- **Unsubscribe detection** — Finds unsubscribe links and opens them in your browser
- **Smart categorization** — Auto-detects newsletters, notifications, and transactional emails
- **Incremental sync** — Only fetches new emails after the initial scan
- **Privacy-first** — Everything runs locally on your Mac, no cloud servers

## Tech Stack

- **Framework:** Flutter (Dart)
- **State management:** Riverpod
- **Database:** SQLite via Drift
- **API:** Gmail API with OAuth 2.0
- **Platform:** macOS (Windows/Linux planned)

## Getting Started

```bash
# Clone the repo
git clone https://github.com/mentilead/mailstrom-app.git
cd mailstrom-app/mailstrom

# Install dependencies
flutter pub get

# Run the app
flutter run -d macos
```

You'll need a `google_oauth_credentials.json` file with your Google OAuth client credentials in the project root. See [Google's OAuth 2.0 guide](https://developers.google.com/identity/protocols/oauth2) for setup.

## License

[MIT](LICENSE)

## Website

[mailstrom.mentilead.com](https://mailstrom.mentilead.com)
