#!/bin/bash
#
# Downloads BeeWare's Python-Apple-support builds and assembles a universal
# Python.xcframework (macOS + iOS device + iOS simulator) under Frameworks/.
#
# `xcodebuild -create-xcframework` only keeps each slice's Python.framework. On
# macOS that's enough — the stdlib lives inside the framework. On iOS the stdlib
# ships *next to* the framework, so it gets dropped; we restore it afterwards,
# along with BeeWare's build/ helper scripts that the consuming app runs to stage
# and code-sign the stdlib into its bundle (see README "iOS integration").
set -euo pipefail

PYTHON_VERSION="3.13"
SUPPORT_BUILD="b12"
BASE_URL="https://github.com/beeware/Python-Apple-support/releases/download/${PYTHON_VERSION}-${SUPPORT_BUILD}"

ROOT="$(cd "$(dirname "$0")" && pwd)"
OUT="${ROOT}/Frameworks/Python.xcframework"
WORK="$(mktemp -d)"
trap 'rm -rf "${WORK}"' EXIT

echo "Setting up EmbeddedPython frameworks (Python ${PYTHON_VERSION}, ${SUPPORT_BUILD})..."
mkdir -p "${ROOT}/Frameworks"

echo "Downloading macOS support..."
curl -fL -o "${WORK}/macos.tar.gz" "${BASE_URL}/Python-${PYTHON_VERSION}-macOS-support.${SUPPORT_BUILD}.tar.gz"

echo "Downloading iOS support..."
curl -fL -o "${WORK}/ios.tar.gz" "${BASE_URL}/Python-${PYTHON_VERSION}-iOS-support.${SUPPORT_BUILD}.tar.gz"

echo "Extracting..."
mkdir -p "${WORK}/macos" "${WORK}/ios"
tar -xzf "${WORK}/macos.tar.gz" -C "${WORK}/macos"
tar -xzf "${WORK}/ios.tar.gz" -C "${WORK}/ios"

echo "Assembling universal xcframework..."
rm -rf "${OUT}"
xcodebuild -create-xcframework \
  -framework "${WORK}/macos/Python.xcframework/macos-arm64_x86_64/Python.framework" \
  -framework "${WORK}/ios/Python.xcframework/ios-arm64/Python.framework" \
  -framework "${WORK}/ios/Python.xcframework/ios-arm64_x86_64-simulator/Python.framework" \
  -output "${OUT}"

echo "Restoring iOS standard library + build scripts..."
for slice in ios-arm64 ios-arm64_x86_64-simulator; do
    src="${WORK}/ios/Python.xcframework/${slice}"
    for extra in lib platform-config; do
        if [ -d "${src}/${extra}" ]; then
            cp -R "${src}/${extra}" "${OUT}/${slice}/"
        fi
    done
done
cp -R "${WORK}/ios/Python.xcframework/build" "${OUT}/build"

echo "✅ Setup complete! ${OUT} is ready (macOS + iOS, with iOS stdlib)."
