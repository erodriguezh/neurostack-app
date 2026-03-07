#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

WHITE_TOKEN_PATTERN='kitColors\.white(90|80|70|60|50|40|30|20|10|05|02)'

# Adaptive paths where whiteXX must not appear.
DENYLIST_DIRS=(
  "lib/home"
  "lib/library"
  "lib/progress"
  "lib/settings"
)

# Core widgets are adaptive unless explicitly dark-first or legacy-dark only.
DENYLIST_WIDGET_FILES=()
while IFS= read -r file; do
  DENYLIST_WIDGET_FILES+=("$file")
done < <(
  find lib/core/ui/widgets -type f -name "*.dart" \
    ! -name "dark_theme_scope.dart" \
    ! -name "app_grid_background.dart" \
    | sort
)

# Dark-first paths are intentionally excluded from checks:
# - lib/features/auth/
# - lib/features/onboarding/
# - lib/features/offline/ (legacy path kept for policy compatibility)
# - lib/offline/ (current path)
# - lib/paywall/
# - lib/startup/

matches=()

for dir in "${DENYLIST_DIRS[@]}"; do
  if [[ -d "$dir" ]]; then
    while IFS= read -r line; do
      matches+=("$line")
    done < <(grep -RInE --include="*.dart" "$WHITE_TOKEN_PATTERN" "$dir" || true)
  fi
done

if ((${#DENYLIST_WIDGET_FILES[@]} > 0)); then
  while IFS= read -r line; do
    matches+=("$line")
  done < <(grep -nE "$WHITE_TOKEN_PATTERN" "${DENYLIST_WIDGET_FILES[@]}" || true)
fi

if ((${#matches[@]} > 0)); then
  echo "ERROR: Adaptive surfaces must not use kitColors.whiteXX tokens."
  echo "Use ColorScheme/AppSemanticColors for adaptive routes."
  echo
  echo "Denylist:"
  printf '  - %s\n' "${DENYLIST_DIRS[@]}"
  echo "  - lib/core/ui/widgets/*.dart (excluding dark_theme_scope.dart and app_grid_background.dart)"
  echo
  echo "Matches:"
  printf '%s\n' "${matches[@]}"
  exit 1
fi

echo "OK: No whiteXX usage found in adaptive denylist paths."
