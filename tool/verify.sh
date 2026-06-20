#!/usr/bin/env bash
set -euo pipefail

format_paths=(lib test)

if [[ -d integration_test ]]; then
  format_paths+=(integration_test)
fi

if [[ -d tool ]]; then
  format_paths+=(tool)
fi

dart format \
  --output=none \
  --set-exit-if-changed \
  "${format_paths[@]}"

flutter analyze --fatal-infos
flutter test
