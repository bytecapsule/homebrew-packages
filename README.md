# bytecapsule packages

Shared Homebrew tap and Scoop bucket for bytecapsule tools. The binaries
themselves live in each product's GitHub Releases; this repository only holds
the version + URL + SHA-256 index.

## Install

```bash
brew tap bytecapsule/packages
brew install doscapsule
```

```powershell
scoop bucket add bytecapsule https://github.com/bytecapsule/homebrew-packages
scoop install doscapsule
```

Upgrade:

```bash
brew update && brew upgrade doscapsule
scoop update doscapsule
```

## Layout

```
Formula/<product>.rb      Homebrew formula
bucket/<product>.json     Scoop manifest
products/<product>.env    asset names + product repo for the updater
scripts/update-package.sh one product, one tag
.github/workflows/update-package.yml
```

## Adding a product

1. Add `Formula/<product>.rb` and `bucket/<product>.json`.
2. Add `products/<product>.env` with `PRODUCT_REPO` and the three asset
   prefixes.
3. In the product repository, dispatch `release-published` with
   `client_payload.product=<product>` and `client_payload.tag=<tag>` after the
   release is published.

The workflow downloads that release's zips, computes the hashes, and commits
the updated formula/manifest. No binaries are stored here.

## Manual update

```bash
scripts/update-package.sh doscapsule 20261125-3
```
