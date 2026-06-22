#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
# Copy any built .so files from known .build/* directories into Android jniLibs.
# Supports common host target folder names and maps them to Android ABI folders.

find_swift_android_lib_root() {
  local swift_sdks_dir candidate
  swift_sdks_dir="$HOME/Library/org.swift.swiftpm/swift-sdks"

  for candidate in "$swift_sdks_dir"/*_android.artifactbundle/swift-android/swift-resources/usr/lib; do
    if [ -d "$candidate" ]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  return 1
}

copy_swift_runtime_libs() {
  local swift_android_lib_root abi_source_dir target_dir copied

  swift_android_lib_root=$(find_swift_android_lib_root) || return 0

  case "$1" in
    x86_64) abi_source_dir="swift-x86_64/android" ;;
    arm64-v8a) abi_source_dir="swift-aarch64/android" ;;
    *) return 0 ;;
  esac

  target_dir="$ROOT_DIR/Android/app/src/main/jniLibs/$1"
  mkdir -p "$target_dir"

  copied=0
  for so in "$swift_android_lib_root/$abi_source_dir"/*.so; do
    [ -e "$so" ] || continue
    echo "Copying $so -> $target_dir/"
    cp -v "$so" "$target_dir/"
    chmod 644 "$target_dir/$(basename "$so")"
    copied=$((copied+1))
  done

  echo "Copied $copied Swift runtime .so files to $target_dir"
}

copied_total=0

for build_dir in "$ROOT_DIR"/.build/*/debug; do
  [ -d "$build_dir" ] || continue

  # Determine ABI folder name based on build_dir name
  arch_name=$(basename "$(dirname "$build_dir")")
  case "$arch_name" in
    *x86_64*) abi_dir="x86_64" ;;
    *aarch64*|*arm64*) abi_dir="arm64-v8a" ;;
    *)
      echo "Skipping unsupported Android ABI source: $arch_name"
      continue
      ;;
  esac

  target_dir="$ROOT_DIR/Android/app/src/main/jniLibs/$abi_dir"
  mkdir -p "$target_dir"

  copied=0
  for so in "$build_dir"/lib*.so; do
    [ -e "$so" ] || continue
    echo "Copying $so -> $target_dir/"
    cp -v "$so" "$target_dir/"
    chmod 644 "$target_dir/$(basename "$so")"
    copied=$((copied+1))
  done

  echo "Copied $copied .so files to $target_dir"
  copied_total=$((copied_total+copied))
done

copy_swift_runtime_libs x86_64
copy_swift_runtime_libs arm64-v8a

echo "Total copied .so files: $copied_total"
exit 0
