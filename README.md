# MAOBAO

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
flutter run
```

For Web UI preview:

```sh
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 8080
```

## Test

```sh
flutter test
```

The Android build disables OS backup and uses `FlutterFragmentActivity` for biometric authentication.
