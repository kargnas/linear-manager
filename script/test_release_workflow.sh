#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKFLOW="$ROOT_DIR/.github/workflows/build-release.yml"

fail() {
  echo "release workflow contract failed: $*" >&2
  exit 1
}

[[ -f "$WORKFLOW" ]] || fail "missing workflow"

require() {
  local pattern="$1"
  local message="$2"
  grep -Eq -- "$pattern" "$WORKFLOW" || fail "$message"
}

require "runs-on:[[:space:]]*macos-26" "macos-26 runner is required"
require "-[[:space:]]*['\"]?v\\*['\"]?[[:space:]]*$" "v* tag trigger is required"
require "workflow_dispatch:" "workflow_dispatch trigger is required"
require "^[[:space:]]+version:" "version dispatch input is required"
require "required:[[:space:]]*true" "version input must be required"
require "group:[[:space:]]*build-release" "build-release concurrency group is required"
require "cancel-in-progress:[[:space:]]*false" "in-progress releases must not be cancelled"
require "vMAJOR\\.MINOR\\.PATCH" "strict version contract is required"
require "github\.sha" "push tag SHA must be checked"
require "components.*999|999.*components" "version component limit is required"
require "1000000|1000" "build number formula is required"
require "BUILD_NUMBER.*[>][[:space:]]*0|build number must be positive" "positive build number is required"
require "repository:[[:space:]]*kargnas/linear-manager-src" "private source repository is required"
require "path:[[:space:]]*source" "source checkout path is required"
require "persist-credentials:[[:space:]]*false" "source credentials must not persist"
require "SOURCE_REPO_DEPLOY_KEY" "source deploy key is required"
require "actions/checkout@[0-9a-f]{40}" "checkout action must be SHA pinned"
require "refs/tags/" "exact source tag ref must be verified"
require "rev-parse.*SOURCE_REF" "source tag commit must be resolved"
require "swift test" "source tests are required"
require "swift test --no-parallel" "source tests must avoid shared-runner timing contention"
require "ComposerViewModelTests/cachedTypingLatency" "hardware-specific composer latency test must stay outside the release gate"
require "HeuristicIssueMatcherTests/largeSnapshotLatency" "hardware-specific matcher latency test must stay outside the release gate"
require "BUILD_CERTIFICATE_BASE64" "certificate secret is required"
require "P12_PASSWORD" "certificate password secret is required"
require "find-identity" "imported identity must be checked"
require "Developer ID Application" "Developer ID Application identity is required"
require "package_macos_app\.sh --configuration release" "source release package command is required"
require "--timestamp secure" "secure timestamp is required"
require "notarytool submit" "notarization is required"
require "--timeout 30m" "notarization timeout is required"
require "APPLE_ID" "Apple ID notarization credentials are required"
require "APPLE_APP_PASSWORD" "Apple app password is required"
require "APPLE_TEAM_ID" "Apple team ID is required"
require "hdiutil create" "DMG creation is required"
require "sign_update" "Sparkle signing is required"
require "Sparkle-2\.9\.4" "Sparkle 2.9.4 distribution is required"
require "tar -xJf.*SPARKLE_ROOT" "Sparkle archive must extract beside sign_update"
require "SPARKLE_PRIVATE_KEY" "Sparkle private key is required"
require "sparkle:edSignature" "appcast EdDSA signature is required"
require 'sparkle:version=.{0,20}BUILD_NUMBER|sparkle:version="\$BUILD_NUMBER"' "appcast build version is required"
require 'sparkle:shortVersionString=.{0,20}VERSION|sparkle:shortVersionString="\$VERSION"' "appcast short version is required"
require 'releases/download/\$TAG' "appcast must point at the public release"
require "stat -f '%z'|stat -f \"%z\"" "appcast length must match DMG bytes"
require "gh release view" "existing releases must be refused"
require "github\.token" "public release must use github.token"
require "gh release (create|upload)" "GitHub Release publication is required"
require "if:[[:space:]]*.*always\\(\\)" "credential cleanup must always run"

if grep -A8 -E "^[[:space:]]+push:" "$WORKFLOW" | grep -Eq "branches:|main"; then
  fail "push trigger must be tags-only"
fi

if grep -Eq "source/.*(git push|gh release)|SOURCE_REPO_DEPLOY_KEY.*github\.token" "$WORKFLOW"; then
  fail "source checkout credentials must not publish the public release"
fi

echo "release workflow contract passed"
