# TestFlight Deployment Setup

Your iOS app is ready for automated TestFlight deployment via GitHub Actions.

## Prerequisites

1. **Apple Developer Program** ($99/year)
   - Enroll at: https://developer.apple.com/programs/
   - Required for TestFlight and App Store distribution

2. **App Store Connect**
   - Access: https://appstoreconnect.apple.com
   - Create a new app with Bundle ID: `com.wealthflow.app`

## Step 1: Create App Store Connect API Key

1. Go to App Store Connect → Users and Access → Keys
2. Click "+" to create a new key
3. Name: `GitHub Actions CI`
4. Role: `App Manager` (or `Admin`)
5. Download the `.p8` file — **you can only download it once**
6. Note the **Key ID** and **Issuer ID**

## Step 2: Generate Distribution Certificate

### Option A: Using Xcode (Recommended)
1. Open Xcode → Preferences → Accounts
2. Sign in with your Apple ID
3. Click "Manage Certificates"
4. Click "+" → "Apple Distribution"
5. Xcode will create and download it automatically

### Option B: Using Apple Developer Portal
1. Go to https://developer.apple.com/account/resources/certificates/list
2. Click "+" → "iOS Distribution (App Store and Ad Hoc)"
3. Follow instructions to create a Certificate Signing Request (CSR)
4. Download the `.cer` file
5. Double-click to add to Keychain
6. Export as `.p12` from Keychain Access

## Step 3: Create Provisioning Profile

1. Go to https://developer.apple.com/account/resources/profiles/list
2. Click "+" → "App Store"
3. Select App ID: `com.wealthflow.app`
4. Select your Distribution Certificate
5. Name it: `WealthFlow App Store`
6. Download the `.mobileprovision` file

## Step 4: Add GitHub Secrets

Go to your GitHub repo → Settings → Secrets and variables → Actions → New repository secret

Add these 6 secrets:

| Secret | How to get it |
|--------|---------------|
| `APPLE_CERTIFICATE_BASE64` | Export your `.p12` certificate from Keychain, then run: `base64 -i certificate.p12` |
| `APPLE_CERTIFICATE_PASSWORD` | The password you set when exporting the `.p12` |
| `APPLE_PROVISIONING_PROFILE_BASE64` | Run: `base64 -i WealthFlow_App_Store.mobileprovision` |
| `APPLE_API_KEY_BASE64` | Run: `base64 -i AuthKey_XXX.p8` |
| `APPLE_API_KEY_ID` | The Key ID from App Store Connect (e.g., `ABC123DEF4`) |
| `APPLE_API_ISSUER_ID` | The Issuer ID from App Store Connect |
| `APPLE_TEAM_ID` | Your Apple Developer Team ID (found in Membership details) |

### Quick commands to generate base64 values:

```bash
# Certificate
base64 -i Certificate.p12 | pbcopy

# Provisioning Profile
base64 -i WealthFlow_App_Store.mobileprovision | pbcopy

# API Key
base64 -i AuthKey_XXX.p8 | pbcopy
```

## Step 5: Deploy

Once all secrets are added, push any commit to `main` or go to Actions → "Build & Deploy to TestFlight" → Run workflow.

The workflow will:
1. Generate the Xcode project with xcodegen
2. Build and archive the app
3. Upload to TestFlight automatically

You'll receive an email from Apple when the build is ready for testing in TestFlight.

## Troubleshooting

- **"No signing certificate found"** → Check that `APPLE_CERTIFICATE_BASE64` is correct and the certificate includes the private key
- **"Provisioning profile doesn't match"** → Ensure the profile Bundle ID matches `com.wealthflow.app`
- **Upload fails** → Verify your API key has `App Manager` role and hasn't expired
