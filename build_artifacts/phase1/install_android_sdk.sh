#!/bin/bash
# Android SDK installation script for Project Hydra Phase 1
# Run this in WSL Kali Linux

set -e

echo "=== Installing Android SDK ==="
echo "This requires manual configuration of Android Studio or SDK command-line tools"
echo ""

SDK_DIR="${ANDROID_SDK_ROOT:-/opt/android-sdk}"
echo "SDK directory: $SDK_DIR"

if [ ! -d "$SDK_DIR" ]; then
    echo "Creating SDK directory..."
    sudo mkdir -p "$SDK_DIR"
    sudo chown $USER:$USER "$SDK_DIR"
fi

echo ""
echo "=== Manual Steps Required ==="
echo "1. Download Android Studio from https://developer.android.com/studio"
echo "2. Install Android SDK Platform 34 and Build Tools"
echo "3. Install NDK (r23 or later)"
echo "4. Set ANDROID_SDK_ROOT environment variable:"
echo "   export ANDROID_SDK_ROOT=$SDK_DIR"
echo "5. Update android/local.properties with:"
echo "   sdk.dir=$SDK_DIR"
echo ""
echo "OR use command-line tools:"
echo "  wget https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip"
echo "  unzip commandlinetools-linux-*.zip -d $SDK_DIR"
echo "  $SDK_DIR/cmdline-tools/bin/sdkmanager 'platform-tools' 'platforms;android-34' 'build-tools;34.0.0' 'ndk;23.1.7779620'"

