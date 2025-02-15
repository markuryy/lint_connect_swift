# lint connect - AltStore Distribution

This repository contains the necessary files to distribute lint connect through AltStore.

## Adding the Source to AltStore

1. Open AltStore on your iOS device
2. Go to the "Browse" tab
3. Tap the "Sources" button in the top-right corner
4. Tap the "+" button
5. Enter the following URL:
   ```
   https://raw.githubusercontent.com/markuryy/lint_connect_swift/main/apps.json
   ```
6. Tap "Add Source"

## Source Contents

The source includes:
- lint connect app (v1.2.0)
- App icon and screenshots
- Detailed app description and features
- Privacy permissions information

## Requirements

- iOS 18.0 or later
- AltStore installed on your device
- Active AltStore patreon subscription (for app installation)

## Support

For support, please:
1. Check the [GitHub repository](https://github.com/markuryy/lint_connect_swift)
2. Visit [markury.dev](https://markury.dev)
3. Open an issue on GitHub if you encounter problems

## Notes for Developers

If you're forking this repository to create your own AltStore source:

1. Update the following in `apps.json`:
   - Bundle identifier
   - Developer name
   - Website URL
   - Icon and screenshot URLs
   - App version information
   - Download URL for the IPA file

2. Host your IPA file in a publicly accessible location (e.g., GitHub Releases)

3. Update all URLs to point to your repository/hosting location

4. Ensure your IPA is properly signed and includes all required entitlements 