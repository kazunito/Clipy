#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

UPSTREAM_REMOTE="${UPSTREAM_REMOTE:-upstream}"
UPSTREAM_BRANCH="${UPSTREAM_BRANCH:-develop}"
LOCAL_BRANCH="${LOCAL_BRANCH:-develop}"
ORIGIN_REPO="${ORIGIN_REPO:-kazunito/Clipy}"
# Sign releases with a stable self-signed identity by default so the macOS
# Accessibility (TCC) grant persists across updates. Override with CODE_SIGN_IDENTITY=-
# for a plain ad-hoc build. The named identity must exist in the login keychain.
export CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY:-Clipy Self}"

# ---------- 事前チェック ----------
CURRENT_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
if [[ "$CURRENT_BRANCH" != "$LOCAL_BRANCH" ]]; then
  echo "error: must run from '$LOCAL_BRANCH' branch (currently on '$CURRENT_BRANCH')" >&2
  exit 1
fi

if ! git diff-index --quiet HEAD --; then
  echo "error: working tree has uncommitted changes:" >&2
  git status --short >&2
  exit 1
fi

if ! git remote get-url "$UPSTREAM_REMOTE" >/dev/null 2>&1; then
  echo "error: '$UPSTREAM_REMOTE' remote not configured" >&2
  echo "  hint: git remote add $UPSTREAM_REMOTE https://github.com/Clipy/Clipy.git" >&2
  exit 1
fi

# ---------- upstream 取り込み ----------
echo "==> Fetching $UPSTREAM_REMOTE..."
git fetch "$UPSTREAM_REMOTE"

NEW_COMMITS=$(git rev-list --count "$LOCAL_BRANCH..$UPSTREAM_REMOTE/$UPSTREAM_BRANCH")
if [[ "$NEW_COMMITS" -eq 0 ]]; then
  echo "==> No new upstream commits."
  read -r -p "Continue with rebuild and release? (y/N): " yn
  case "$yn" in
    [Yy]*) ;;
    *) echo "Aborted."; exit 0;;
  esac
else
  echo "==> $NEW_COMMITS new upstream commits:"
  git log --oneline "$LOCAL_BRANCH..$UPSTREAM_REMOTE/$UPSTREAM_BRANCH"
  echo ""
  echo "==> Merging $UPSTREAM_REMOTE/$UPSTREAM_BRANCH..."
  if ! git merge "$UPSTREAM_REMOTE/$UPSTREAM_BRANCH" --no-edit; then
    echo "error: merge has conflicts. Resolve manually, commit, then re-run." >&2
    exit 1
  fi
fi

# ---------- ビルド ----------
echo "==> Building Clipy.app and dmg..."
./scripts/package_dmg.sh

# ---------- タグ採番 ----------
VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" \
  build/dist/dmg-root/Clipy.app/Contents/Info.plist)
TAG_PREFIX="v${VERSION}-arm64"

LAST_N=$(git tag --list "${TAG_PREFIX}.*" \
  | sed -E "s/^${TAG_PREFIX}\.([0-9]+)$/\1/" \
  | grep -E '^[0-9]+$' \
  | sort -n | tail -1 || true)
if [[ -z "$LAST_N" ]]; then
  NEXT_N=1
else
  NEXT_N=$((LAST_N + 1))
fi
NEW_TAG="${TAG_PREFIX}.${NEXT_N}"

echo "==> Tagging as $NEW_TAG"
git tag -a "$NEW_TAG" -m "Apple Silicon arm64 build (build ${NEXT_N})"

# ---------- push ----------
echo "==> Pushing $LOCAL_BRANCH and $NEW_TAG to origin..."
git push origin "$LOCAL_BRANCH"
git push origin "$NEW_TAG"

# ---------- リリース作成 ----------
echo "==> Creating GitHub release on $ORIGIN_REPO..."
NOTES=$(cat <<EOF
Apple Silicon (arm64) 専用ビルド（安定した自己署名証明書で署名・Apple 公証なし）

## インストール方法
1. dmg を開き、Clipy.app を Applications にドラッグ（既存があれば置き換え）
2. 初回起動はブロックされます。**システム設定 → プライバシーとセキュリティ** を開き、
   一番下の Clipy の項目で **「このまま開く」** を押してから再度起動（旧 macOS では右クリック →「開く」）
3. アクセシビリティを許可: **システム設定 → プライバシーとセキュリティ → アクセシビリティ**。
   以前のビルドの項目が残っていれば削除してから Clipy.app を追加して有効化。
   毎回同じ証明書で署名しているため、**アップデート後もこの許可は維持され、再許可は不要**です。

## 動作環境
- Apple Silicon Mac (M1/M2/M3/M4 以降) 専用
- macOS 13 Ventura 以降が必要
EOF
)

gh release create "$NEW_TAG" \
  build/dist/Clipy-Release-arm64.dmg \
  --repo "$ORIGIN_REPO" \
  --title "Clipy ${VERSION} Apple Silicon (build ${NEXT_N})" \
  --prerelease \
  --notes "$NOTES"

echo ""
echo "==> Done. Release: https://github.com/${ORIGIN_REPO}/releases/tag/${NEW_TAG}"
