# KeyNest

Local-first encrypted password manager built with Flutter.

## Features

- AES-256-GCM encrypted local vault
- Master-key derivation with PBKDF2-HMAC-SHA256 and a random 32-byte salt
- Optional biometric unlock backed by platform secure storage
- Credential create, edit, delete, search, favorite, copy, and website launch
- Secure password generator
- Automatic locking and clipboard clearing
- Encrypted local backup import/export
- Stable letter avatars when no official account logo is configured

## Run

```sh
make dev          # Web: http://127.0.0.1:8080
make dev-android  # First available Android device
```

Overrides:

```sh
WEB_PORT=8081 make dev
ANDROID_DEVICE=emulator-5554 make dev-android
```

## Test

```sh
flutter test
```

The Android build disables OS backup and uses `FlutterFragmentActivity` for biometric authentication.
