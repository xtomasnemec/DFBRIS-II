#!/bin/zsh

set -euo pipefail

function ensure_xcode_selected() {
    if [[ ! -d /Applications/Xcode.app ]]; then
        echo "Xcode.app is not installed. Install Xcode from https://developer.apple.com/xcode/ and open it once, then re-run this script."
        return 1
    fi

    local developer_dir
    developer_dir="$(/usr/bin/xcode-select -p 2>/dev/null || true)"

    if [[ "$developer_dir" != "/Applications/Xcode.app/Contents/Developer" ]]; then
        echo "Xcode is installed but not currently selected for command-line tools."
        echo "Active developer directory: ${developer_dir:-<unknown>}"
        echo
        echo "Run this to select Xcode:" \
            "sudo xcode-select -s /Applications/Xcode.app/Contents/Developer"
        echo
        echo "If you then get a license/components error, run:" \
            "sudo xcodebuild -runFirstLaunch"
        return 1
    fi

    if ! /usr/bin/xcodebuild -version >/dev/null 2>&1; then
        echo "Xcode is installed but not currently selected for command-line tools."
        echo "Active developer directory: ${developer_dir:-<unknown>}"
        echo
        echo "Run this to select Xcode:" \
            "sudo xcode-select -s /Applications/Xcode.app/Contents/Developer"
        echo
        echo "If you then get a license/components error, run:" \
            "sudo xcodebuild -runFirstLaunch"
        return 1
    fi
}

function ensure_ios_platform_installed() {
    if ! /usr/bin/xcrun --sdk iphoneos --show-sdk-path >/dev/null 2>&1; then
        echo "iOS platform SDK is not installed in Xcode components."
        echo
        echo "Open Xcode -> Settings -> Components and install the iOS platform, then re-run this script."
        return 1
    fi

    local project="dfbris-ii/Darwin/DFBRIS2.xcodeproj"
    local scheme="DFBRIS2 App"
    local destinations
    destinations="$(/usr/bin/xcodebuild -project "$project" -scheme "$scheme" -showdestinations 2>&1)" || true

    local available
    available="$(printf "%s\n" "$destinations" | awk '/Available destinations/{flag=1;next}/Ineligible destinations/{flag=0}flag')"

    if printf "%s\n" "$available" | grep -q "{ platform:iOS"; then
        return 0
    fi

    if printf "%s\n" "$destinations" | grep -q "Please download and install the platform"; then
        local sdk_version
        sdk_version="$(/usr/bin/xcodebuild -sdk iphoneos -version SDKVersion 2>/dev/null | head -n 1 || true)"
        if [[ -z "$sdk_version" ]]; then
            sdk_version="26.4"
        fi

        echo "iOS destinations are not eligible yet; preparing iOS Device Support (this may take a while)."
        echo "If this fails, open Xcode -> Settings -> Components and install the iOS platform/device support."
        /usr/bin/xcodebuild -prepareDeviceSupport -platform iOS -osVersion "$sdk_version" || true

        destinations="$(/usr/bin/xcodebuild -project "$project" -scheme "$scheme" -showdestinations 2>&1)" || true
        available="$(printf "%s\n" "$destinations" | awk '/Available destinations/{flag=1;next}/Ineligible destinations/{flag=0}flag')"
        if printf "%s\n" "$available" | grep -q "{ platform:iOS"; then
            return 0
        fi
    fi

    echo "iOS destinations are still not available for Xcode builds."
    echo
    echo "Open Xcode -> Settings -> Components and install the iOS platform/device support, then re-run this script."
    return 1
}

# download xcode-cli tools
if [[ ! -d /Library/Developer/CommandLineTools ]]; then
    xcode-select --install
fi

# download brew and dependencies
if command -v brew >/dev/null 2>&1; then
    echo "Homebrew is already installed."
else
    echo "Homebrew is not installed. Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

brew update
brew upgrade
brew tap skiptools/skip
brew install --formula skip
brew install --cask temurin
brew install --cask android-ndk android-platform-tools android-commandlinetools

# download android swift sdk
if command -v swiftly >/dev/null 2>&1; then
    echo "Swift is already installed."
else
    echo "Swift is not installed. Installing Swift..."
    curl -fL -o swiftly.pkg https://download.swift.org/swiftly/darwin/swiftly.pkg && \
        installer -pkg swiftly.pkg -target CurrentUserHomeDirectory && \
        rm -f swiftly.pkg && \
        ~/.swiftly/bin/swiftly init --quiet-shell-followup
fi

. "${SWIFTLY_HOME_DIR:-$HOME/.swiftly}/env.sh"
hash -r

# setup swiftly and download iOS and Android toolchains
swiftly link --assume-yes
swiftly install latest --assume-yes
swiftly use latest --assume-yes
swift sdk install https://download.swift.org/swift-6.3.1-release/android-sdk/swift-6.3.1-RELEASE/swift-6.3.1-RELEASE_android.artifactbundle.tar.gz --checksum 8193a4e96538635131a154736c8896fba0e5a1c30e065524f00ed78719bac35a

# accept Android SDK licenses non-interactively
export ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-$HOME/Library/Android/sdk}"
export ANDROID_HOME="$ANDROID_SDK_ROOT"
if ! java -version >/dev/null 2>&1; then
    echo "Java runtime is missing (required for Android sdkmanager)."
    echo
    echo "If the Homebrew Temurin install prompted for sudo, re-run this script and complete the prompt."
    exit 1
fi

export JAVA_HOME="$(/usr/libexec/java_home)"
export PATH="$JAVA_HOME/bin:$PATH"
mkdir -p "$ANDROID_SDK_ROOT" "$HOME/.android"
touch "$HOME/.android/repositories.cfg"
if ! command -v sdkmanager >/dev/null 2>&1; then
    echo "sdkmanager not found in PATH (expected from the android-commandlinetools Homebrew cask)."
    exit 1
fi

yes | sdkmanager --sdk_root="$ANDROID_SDK_ROOT" --licenses >/dev/null

# init skip
ensure_xcode_selected || exit 1
ensure_ios_platform_installed || exit 1

# GitHub CLI + submodules
if command -v gh >/dev/null 2>&1; then
    GH_PAGER=cat PAGER=cat gh auth setup-git >/dev/null 2>&1 || true
fi

# Use versioned hooks (see .githooks/) and make pushes include submodule commits.
git config core.hooksPath .githooks
git config push.recurseSubmodules on-demand
git config submodule.recurse true
chmod +x .githooks/pre-push >/dev/null 2>&1 || true

# Ensure submodules are present for builds.
git submodule update --init --recursive

skip checkup
