#!/bin/bash
# Flutter build script for WanderLess app
# Run on any x86_64 Linux VM with Flutter SDK installed
#
# Setup on a fresh x86_64 VM:
#   sudo apt update && sudo apt install -y curl git unzip xz-utils zip libglu1-mesa
#   git clone https://github.com/nickswalker/nvm.git ~/.nvm 2>/dev/null || true
#   curl -fsSL https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.0-stable.tar.xz | tar xJ -C $HOME
#   echo 'export PATH="$HOME/flutter/bin:$PATH"' >> ~/.bashrc
#   export PATH="$HOME/flutter/bin:$PATH"
#
# Then run this script from the app directory:
#   ./build.sh

set -e

FLUTTER_DIR="${HOME}/flutter"
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_OUTPUT="${PROJECT_DIR}/build_output"

echo "=== WanderLess Flutter Build ==="
echo "Project: ${PROJECT_DIR}"
echo "Flutter: ${FLUTTER_DIR}"

# Detect Flutter
if [ -d "${FLUTTER_DIR}" ]; then
    export PATH="${FLUTTER_DIR}/bin:${PATH}"
elif command -v flutter &>/dev/null; then
    echo "Using system Flutter"
else
    echo "ERROR: Flutter not found. Install Flutter SDK first."
    echo "  mkdir -p ~/flutter"
    echo "  cd ~/flutter"
    echo "  curl -fsSL https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.0-stable.tar.xz | tar xJ"
    echo "  export PATH=\"\$HOME/flutter/bin:\$PATH\""
    exit 1
fi

# Verify architecture
ARCH=$(uname -m)
if [ "$ARCH" != "x86_64" ]; then
    echo "WARNING: Running on $ARCH. Flutter Linux builds require x86_64."
fi

echo ""
echo "=== Flutter doctor ==="
flutter doctor --verbose 2>&1 | head -30

echo ""
echo "=== Getting dependencies ==="
cd "${PROJECT_DIR}"
flutter pub get

echo ""
echo "=== Running flutter analyze ==="
flutter analyze || true

echo ""
echo "=== Building debug APK ==="
mkdir -p "${BUILD_OUTPUT}"
flutter build apk --debug --output="${BUILD_OUTPUT}/wanderless-debug.apk"

echo ""
echo "=== Build complete ==="
ls -lh "${BUILD_OUTPUT}/wanderless-debug.apk"
echo ""
echo "APK location: ${BUILD_OUTPUT}/wanderless-debug.apk"
