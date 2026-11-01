#!/bin/bash
# Builds a signed release of Amoxtli. Publishing stays a manual step.
#
#   packaging/release.sh developer-id   Notarized zip and Homebrew cask in build/release
#   packaging/release.sh app-store      Uploads the build to App Store Connect
set -euo pipefail

readonly ROOT="$(cd "$(dirname "$0")/.." && pwd)"
readonly PROJECT="$ROOT/Amoxtli.xcodeproj"
readonly SCHEME="Amoxtli"
readonly OUT="$ROOT/build/release"
readonly ARCHIVE="$OUT/Amoxtli.xcarchive"
readonly EXPORT="$OUT/export"
readonly APP="$EXPORT/Amoxtli.app"
readonly NOTARY_PROFILE="${NOTARY_PROFILE:-amoxtli-notary}"

die() { echo "error: $*" >&2; exit 1; }
step() { echo "==> $*"; }

build_setting() {
  xcodebuild -project "$PROJECT" -target "$SCHEME" -showBuildSettings 2>/dev/null |
    awk -F ' = ' -v name="$1" '$1 ~ "^ *" name "$" { print $2; exit }'
}

require_clean_tree() {
  [[ -z "$(git -C "$ROOT" status --porcelain)" ]] ||
    die "the working tree has uncommitted changes; a release must match a commit"
}

require_unused_tag() {
  local tag="v$1"
  if git -C "$ROOT" rev-parse -q --verify "refs/tags/$tag" >/dev/null &&
    [[ "$(git -C "$ROOT" rev-parse "$tag^{commit}")" != "$(git -C "$ROOT" rev-parse HEAD)" ]]; then
    die "$tag already points to another commit; bump MARKETING_VERSION"
  fi
}

check_developer_id_setup() {
  xcrun notarytool history --keychain-profile "$NOTARY_PROFILE" >/dev/null 2>&1 ||
    die "notary profile '$NOTARY_PROFILE' not usable; see 'Publicar una versión' in README.md"
  security find-identity -v -p codesigning | grep -q 'Developer ID Application' ||
    echo "warning: no local Developer ID certificate; the export will rely on cloud-managed signing" >&2
}

run_tests() {
  step "Running tests"
  xcodebuild -project "$PROJECT" -scheme "$SCHEME" -destination 'platform=macOS' -quiet test
}

# The commit count gives both channels the same build number, always increasing.
archive() {
  step "Archiving"
  rm -rf "$OUT"
  mkdir -p "$OUT"
  xcodebuild -project "$PROJECT" -scheme "$SCHEME" -configuration Release \
    -destination 'generic/platform=macOS' -archivePath "$ARCHIVE" \
    -allowProvisioningUpdates -quiet \
    CURRENT_PROJECT_VERSION="$(git -C "$ROOT" rev-list --count HEAD)" \
    archive
}

export_archive() {
  xcodebuild -exportArchive -archivePath "$ARCHIVE" -exportPath "$EXPORT" \
    -exportOptionsPlist "$ROOT/packaging/$1" -allowProvisioningUpdates -quiet
}

verify_signature() {
  step "Verifying signature"
  codesign --verify --deep --strict "$APP"
  local details
  details="$(codesign -dvv "$APP" 2>&1)"
  grep -q 'Authority=Developer ID Application' <<<"$details" || die "not signed with Developer ID"
  grep -Eq 'flags=.*runtime' <<<"$details" || die "hardened runtime is off"
  codesign -d --entitlements - --xml "$APP" 2>/dev/null | grep -q 'com.apple.security.app-sandbox' ||
    die "App Sandbox is off"
}

zip_app() {
  rm -f "$1"
  ditto -c -k --keepParent "$APP" "$1"
}

notarize() {
  step "Notarizing (this can take a few minutes)"
  xcrun notarytool submit "$1" --keychain-profile "$NOTARY_PROFILE" --wait
  xcrun stapler staple "$APP"
  xcrun stapler validate "$APP"
  spctl --assess --type execute --verbose "$APP"
}

render_cask() {
  sed -e "s|@VERSION@|$1|g" -e "s|@SHA256@|$2|g" -e "s|@REPO@|$3|g" -e "s|@BUNDLE_ID@|$4|g" \
    "$ROOT/packaging/amoxtli.rb.template" >"$OUT/amoxtli.rb"
}

release_developer_id() {
  local version bundle_id repo zip sha
  version="$(build_setting MARKETING_VERSION)"
  bundle_id="$(build_setting PRODUCT_BUNDLE_IDENTIFIER)"
  repo="${GITHUB_REPO:-$(gh repo view --json nameWithOwner --jq .nameWithOwner)}"
  zip="$OUT/Amoxtli-$version.zip"

  require_clean_tree
  require_unused_tag "$version"
  check_developer_id_setup
  run_tests
  archive
  step "Exporting with Developer ID"
  export_archive ExportOptions-DeveloperID.plist
  verify_signature
  zip_app "$zip"
  notarize "$zip"
  # The zip must be rebuilt so that it carries the stapled ticket.
  zip_app "$zip"
  sha="$(shasum -a 256 "$zip" | cut -d ' ' -f 1)"
  render_cask "$version" "$sha" "$repo" "$bundle_id"

  cat <<EOF

Ready: $zip
SHA-256: $sha

Next, publish the release:
  gh release create v$version "$zip" --repo $repo --title "Amoxtli $version" --generate-notes --target $(git -C "$ROOT" rev-parse HEAD)

Then copy $OUT/amoxtli.rb to Casks/amoxtli.rb in your tap.
EOF
}

release_app_store() {
  require_clean_tree
  require_unused_tag "$(build_setting MARKETING_VERSION)"
  run_tests
  archive
  step "Uploading to App Store Connect"
  export_archive ExportOptions-AppStore.plist
  echo "Uploaded. Finish the submission in App Store Connect."
}

case "${1:-}" in
  developer-id) release_developer_id ;;
  app-store) release_app_store ;;
  *) die "usage: $0 developer-id | app-store" ;;
esac
