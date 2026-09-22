#!/bin/bash
# Runs xcodebuild with a clean toolchain environment.
# Why: an active conda env exports LD/CC/CXX/AR/SDKROOT/*FLAGS, and xcodebuild
# treats env vars as build settings, so it would link with conda's ld and fail.
# Usage: scripts/xcb.sh build|test [extra xcodebuild args...]
set -euo pipefail
cd "$(dirname "$0")/.."
SIMULATOR="${SIMULATOR:-iPhone 14}"
OS="${OS:-16.2}"
exec env -u LD -u CC -u CXX -u AR -u CFLAGS -u CXXFLAGS -u CPPFLAGS -u LDFLAGS -u SDKROOT \
  xcodebuild -scheme DealsApp \
  -destination "platform=iOS Simulator,name=${SIMULATOR},OS=${OS}" \
  -derivedDataPath build/DerivedData \
  "$@"
