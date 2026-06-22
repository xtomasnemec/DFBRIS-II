#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$ROOT_DIR/dfbris-ii"
IOS_ASSET_DIR="$PROJECT_DIR/Darwin/Assets.xcassets"
MODULE_ASSET_DIR="$PROJECT_DIR/Sources/DFBRIS2/Resources/Module.xcassets"
ANDROID_RES_DIR="$PROJECT_DIR/Android/app/src/main/res"
ANDROID_APP_ICON_SOURCE="$PROJECT_DIR/Darwin/AppIcon.icon/Assets/Icon-App-1024x1024@1x.png"

# temp circular icon
CIRCULAR_ICON="/tmp/ic_launcher_circle.png"

# Ensure ANDROID_HOME is set for the Skip and Gradle builds.
export ANDROID_HOME="${ANDROID_HOME:-$HOME/Library/Android/sdk}"

sync_module_assets() {
	mkdir -p "$MODULE_ASSET_DIR"
	rsync -a --delete "$IOS_ASSET_DIR"/ "$MODULE_ASSET_DIR"/
}

make_circular_icon() {
	magick "$ANDROID_APP_ICON_SOURCE" \
		-alpha set \
		\( +clone -alpha extract \
		   -draw "fill black circle 512,512 512,0" \) \
		-compose CopyOpacity -composite \
		"$CIRCULAR_ICON"
}

sync_android_launcher_icon() {
	local -a sizes dirs
	local index size target_dir icon_file foreground_file

	sizes=(48 72 96 144 192)
	dirs=(mipmap-mdpi mipmap-hdpi mipmap-xhdpi mipmap-xxhdpi mipmap-xxxhdpi)

	for index in {1..5}; do
		size="$sizes[$index]"
		target_dir="$ANDROID_RES_DIR/${dirs[$index]}"
		icon_file="$target_dir/ic_launcher.png"
		foreground_file="$target_dir/ic_launcher_foreground.png"

		mkdir -p "$target_dir"

		# use circular icon instead of raw image
		sips -z "$size" "$size" "$CIRCULAR_ICON" --out "$icon_file" >/dev/null

		cp "$icon_file" "$foreground_file"
		chmod 644 "$icon_file" "$foreground_file"
	done
}

cd "$PROJECT_DIR"

make_circular_icon
sync_module_assets
sync_android_launcher_icon

# Build for both x86_64 and aarch64 architectures
skip android run DFBRIS2app