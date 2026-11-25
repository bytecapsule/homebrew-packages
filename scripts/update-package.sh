#!/usr/bin/env bash
# Update one product's Homebrew formula and Scoop manifest from a GitHub
# Release: download the three zips, compute SHA-256, rewrite the URLs/hashes.
#
# Usage: scripts/update-package.sh <product> <tag>
#   product is a file name under products/ (e.g. doscapsule)
set -euo pipefail

PRODUCT="${1:?usage: scripts/update-package.sh <product> <tag>}"
TAG="${2:?usage: scripts/update-package.sh <product> <tag>}"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONF="$ROOT/products/${PRODUCT}.env"
if [[ ! -f "$CONF" ]]; then
  echo "error: unknown product: $PRODUCT (expected $CONF)" >&2
  exit 1
fi
# The payload comes from another repository; keep it to a simple slug.
if [[ ! "$PRODUCT" =~ ^[a-z0-9][a-z0-9-]*$ ]]; then
  echo "error: invalid product: $PRODUCT" >&2
  exit 1
fi
# shellcheck disable=SC1090
source "$CONF"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

BASE="https://github.com/${PRODUCT_REPO}/releases/download/${TAG}"

fetch_sha() { # <asset-prefix> -> sha256 of <prefix>-<tag>.zip
  local asset="$1"
  local file="${asset}-${TAG}.zip"
  curl -fsSL -o "$TMP/$file" "$BASE/$file"
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$TMP/$file" | awk '{print $1}'
  else
    sha256sum "$TMP/$file" | awk '{print $1}'
  fi
}

echo "Resolving ${PRODUCT} ${TAG} from ${PRODUCT_REPO}…"
SHA_ARM="$(fetch_sha "$MACOS_ARM_ASSET")"
SHA_X64="$(fetch_sha "$MACOS_X64_ASSET")"
SHA_WIN="$(fetch_sha "$WINDOWS_ASSET")"
echo "  macos-arm64: ${SHA_ARM}"
echo "  macos-x64  : ${SHA_X64}"
echo "  windows-x64: ${SHA_WIN}"

FORMULA_PATH="$ROOT/$FORMULA"
python3 - "$FORMULA_PATH" "$TAG" "$PRODUCT_REPO" "$MACOS_ARM_ASSET" "$MACOS_X64_ASSET" "$SHA_ARM" "$SHA_X64" <<'PYEOF'
import re, sys
path, tag, repo, arm_asset, x64_asset, sha_arm, sha_x64 = sys.argv[1:8]
s = open(path).read()
base = f'https://github.com/{repo}/releases/download/{tag}'

# Each formula has one arm64 URL and one (non-Windows) x64 URL.
s = re.sub(r'url "https://github\.com/[^"]+/releases/download/[^"/]+/[^"]*arm64[^"]*\.zip"',
           f'url "{base}/{arm_asset}-{tag}.zip"', s)
s = re.sub(r'url "https://github\.com/[^"]+/releases/download/[^"/]+/[^"]*x64[^"]*\.zip"',
           f'url "{base}/{x64_asset}-{tag}.zip"', s)

# The two sha256 values are in file order: arm64 first, x64 second.
shas = iter([sha_arm, sha_x64])
def sub_sha(m):
    try:
        return 'sha256 "' + next(shas) + '"'
    except StopIteration:
        return m.group(0)
s = re.sub(r'sha256 "[0-9a-f]{64}"', sub_sha, s)
open(path, 'w').write(s)
print("  updated:", path)
PYEOF

SCOOP_PATH="$ROOT/$SCOOP"
python3 - "$SCOOP_PATH" "$TAG" "$PRODUCT_REPO" "$WINDOWS_ASSET" "$SHA_WIN" <<'PYEOF'
import json, sys
path, tag, repo, win_asset, sha_win = sys.argv[1:6]
d = json.load(open(path))
d['version'] = tag
d['architecture']['64bit']['url'] = (
    f'https://github.com/{repo}/releases/download/{tag}/{win_asset}-{tag}.zip'
)
d['architecture']['64bit']['hash'] = sha_win
d.setdefault('autoupdate', {}).setdefault('architecture', {}).setdefault('64bit', {})['url'] = (
    f'https://github.com/{repo}/releases/download/$version/{win_asset}-$version.zip'
)
json.dump(d, open(path, 'w'), indent=4)
open(path, 'a').write('\n')
print("  updated:", path)
PYEOF
