# linear-manager

`linear-manager` is the public release-only repository for Linear Manager. Product source code stays in the private `kargnas/linear-manager-src` repository; this repository contains only GitHub Actions configuration and published update assets.

## Release flow

Releases run from `.github/workflows/build-release.yml` on either:

- a pushed `vMAJOR.MINOR.PATCH` tag; or
- a manual workflow dispatch whose required `version` input is the same strict tag form.

Each component must be at most 999. The workflow derives the positive build number `MAJOR*1000000 + MINOR*1000 + PATCH`, checks out the matching private source tag, runs the Swift tests, and creates the signed and notarized app and DMG. Existing public tags and GitHub Releases are refused instead of overwritten.

The workflow is the source of truth for runner, tool, secret, and signing details. Do not copy those values into this README.

## Public assets

Every release contains exactly these two assets:

- `Linear-Manager-VERSION.dmg`
- `appcast.xml`

The appcast is public and points to the release DMG with its exact byte length, Sparkle EdDSA signature, build number, and short version. No source archive or private build material is published.

Latest downloads:

```text
https://github.com/kargnas/linear-manager/releases/latest/download/Linear-Manager-VERSION.dmg
https://github.com/kargnas/linear-manager/releases/latest/download/appcast.xml
```

## Verification

Run the focused contract test from a checkout of this repository:

```bash
bash -n script/test_release_workflow.sh
./script/test_release_workflow.sh
git diff --check
```

After a published release, verify the public appcast and notarized DMG on macOS:

```bash
curl -fsSL https://github.com/kargnas/linear-manager/releases/latest/download/appcast.xml
curl -fsSLO https://github.com/kargnas/linear-manager/releases/latest/download/Linear-Manager-VERSION.dmg
spctl --assess --type open --context context:primary-signature --verbose=4 Linear-Manager-VERSION.dmg
xcrun stapler validate Linear-Manager-VERSION.dmg
```

## Security boundary

The source deploy key is used only by the private-source checkout and is not persisted by `actions/checkout`. The public repository's GitHub token is used only to create the public Release and upload the two release assets. The Developer ID certificate, Apple notarization credentials, and Sparkle signing key are supplied as GitHub Actions secrets, written only under the runner's temporary directory, and removed in an always-run cleanup step. No credential, source archive, or private key belongs in Git history.
