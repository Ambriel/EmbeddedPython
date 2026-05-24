#!/bin/bash
set -e

echo "Setting up PythonKit frameworks..."

mkdir -p Frameworks
mkdir -p /tmp/pythonkit-setup

echo "Downloading Python 3.13 macOS support..."
curl -L -o /tmp/pythonkit-setup/macos.tar.gz \
  https://github.com/beeware/Python-Apple-support/releases/download/3.13-b12/Python-3.13-macOS-support.b12.tar.gz

echo "Downloading Python 3.13 iOS support..."
curl -L -o /tmp/pythonkit-setup/ios.tar.gz \
  https://github.com/beeware/Python-Apple-support/releases/download/3.13-b12/Python-3.13-iOS-support.b12.tar.gz

echo "Extracting..."
mkdir -p /tmp/pythonkit-setup/macos
mkdir -p /tmp/pythonkit-setup/ios
tar -xzf /tmp/pythonkit-setup/macos.tar.gz -C /tmp/pythonkit-setup/macos
tar -xzf /tmp/pythonkit-setup/ios.tar.gz -C /tmp/pythonkit-setup/ios

echo "Building universal xcframework..."
xcodebuild -create-xcframework \
  -framework /tmp/pythonkit-setup/macos/Python.xcframework/macos-arm64_x86_64/Python.framework \
  -framework /tmp/pythonkit-setup/ios/Python.xcframework/ios-arm64/Python.framework \
  -framework /tmp/pythonkit-setup/ios/Python.xcframework/ios-arm64_x86_64-simulator/Python.framework \
  -output Frameworks/Python.xcframework

echo "Cleaning up..."
rm -rf /tmp/pythonkit-setup

echo "✅ Setup complete! Frameworks/Python.xcframework is ready."
