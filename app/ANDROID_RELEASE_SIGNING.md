# Android release signing (Google Play)

This project uses a local-only keystore configuration via `app/android/key.properties`.

## Important (closed testing already published)

Because you already uploaded builds to Google Play (closed testing), you **must keep using the same upload key** for future updates of the same package name (`com.love2learnsign.app`).

If Play App Signing is enabled (recommended), you still need your **upload key** to upload new `.aab` files.

## Setup (local, never commit)

1. Locate your existing upload keystore file (e.g. `upload-keystore.jks`).
2. Copy the example file:

```bash
cp app/android/key.properties.example app/android/key.properties
```

3. Edit `app/android/key.properties` and fill in:

- `storeFile` (**absolute path**, outside the repo if possible)
- `storePassword`
- `keyAlias`
- `keyPassword`

`app/android/key.properties` is gitignored and must remain secret.

## Build a release bundle

From the `app/` folder:

```bash
flutter build appbundle --release
```

Output:

- `app/build/app/outputs/bundle/release/app-release.aab`

## Common issues

- **“Release build requires android/key.properties…”**: you are running a release task without configuring the keystore.
- **Lost upload key**: use Play Console → Play App Signing → “Request upload key reset”.

