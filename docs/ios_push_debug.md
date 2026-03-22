# iOS Push Notification Debug Checklist

Use this checklist when iOS logs show `apns-token-not-set` and FCM token stays null.

## 1) Validate on a physical iPhone first

- APNS tokens are typically unavailable on the iOS simulator.
- In simulator runs, `APNS token not ready` warnings are expected.

## 2) Verify iOS app capabilities and entitlements

- In Xcode target `Runner > Signing & Capabilities`:
  - `Push Notifications` must be enabled.
  - `Background Modes > Remote notifications` must be enabled.
- Confirm `ios/Runner/Runner.entitlements` includes:
  - `aps-environment` with the correct value for your build (`development` or `production`).

## 3) Verify Apple Developer provisioning

- App ID has Push Notifications enabled.
- The installed provisioning profile matches the bundle identifier.
- The provisioning profile includes push entitlement.

## 4) Verify Firebase Cloud Messaging setup

- Firebase project contains the APNs auth key/certificate for the same app.
- `ios/Runner/GoogleService-Info.plist` belongs to the same Firebase app as the bundle ID.

## 5) Expected runtime sequence in logs

On a correctly configured real device, startup logs should eventually show:

- `FCM permission: AUTHORIZED`
- `APNS token ready on check ...`
- `FCM token retrieved: ...`
- `FCM token registered with backend`

If APNS remains unavailable on a real device, re-check steps 2–4.
