#!/usr/bin/env bash
# Sorts loose files at the top of a drive into named folders.
# Only moves files sitting directly in the drive's top level; existing
# folders (game installs, projects) are never touched. Nothing is deleted.
#
# Usage:
#   bash organize-drive.sh            # dry run on "New Volume": shows what would move
#   bash organize-drive.sh --go       # actually move the files
#   bash organize-drive.sh --go /path # use a different folder

set -euo pipefail

GO=0
TARGET=""
for arg in "$@"; do
	case "$arg" in
		--go) GO=1 ;;
		*) TARGET="$arg" ;;
	esac
done

if [[ -z "$TARGET" ]]; then
	TARGET=$(findmnt -rn -o TARGET | grep -i 'new.volume' | head -1 || true)
	TARGET=$(printf '%b' "$TARGET")
fi
if [[ -z "$TARGET" || ! -d "$TARGET" ]]; then
	echo "Can't find New Volume. Open it in Dolphin first, or pass its path:"
	echo "  bash organize-drive.sh /run/media/$USER/New\\ Volume"
	exit 1
fi

folder_for() {
	local ext="${1,,}"
	case "$ext" in
		jpg|jpeg|png|gif|webp|bmp|tif|tiff|heic|svg|ico|psd) echo "Images" ;;
		mp4|mkv|mov|avi|webm|wmv|flv|m4v|mpg|mpeg|3gp) echo "Videos" ;;
		rbxl|rbxlx|rbxm|rbxmx) echo "Roblox" ;;
		exe|msi|iso|appimage|apk|lnk|url) echo "Games & Apps" ;;
		mp3|wav|flac|ogg|m4a|aac|wma|opus) echo "Music & Audio" ;;
		pdf|doc|docx|odt|txt|rtf|md|xls|xlsx|ods|csv|ppt|pptx|odp) echo "Documents" ;;
		zip|rar|7z|tar|gz|xz|bz2|zst) echo "Archives" ;;
		lua|luau|py|js|ts|json|html|css|sh|cpp|c|cs|java) echo "Code" ;;
		ttf|otf|woff|woff2) echo "Fonts" ;;
		*) echo "Other" ;;
	esac
}

# Picks a free name so nothing gets overwritten: "pic.png" -> "pic (2).png".
free_name() {
	local dir="$1" name="$2" base ext n=2 candidate
	candidate="$dir/$name"
	[[ ! -e "$candidate" ]] && { echo "$candidate"; return; }
	if [[ "$name" == *.* ]]; then base="${name%.*}"; ext=".${name##*.}"; else base="$name"; ext=""; fi
	while [[ -e "$dir/$base ($n)$ext" ]]; do n=$((n + 1)); done
	echo "$dir/$base ($n)$ext"
}

declare -A counts=()
self="$(realpath "$0")"

echo "Drive: $TARGET"
if (( GO )); then echo "Mode: MOVING FILES"; else echo "Mode: dry run (nothing will move; add --go to do it)"; fi
echo

shopt -s nullglob dotglob
for path in "$TARGET"/*; do
	[[ -f "$path" ]] || continue
	[[ "$(realpath "$path")" == "$self" ]] && continue
	name="$(basename "$path")"
	# Skip Windows/system files that belong at the drive root.
	case "${name,,}" in
		desktop.ini|thumbs.db|autorun.inf|pagefile.sys|hiberfil.sys|swapfile.sys|.*) continue ;;
	esac
	if [[ "$name" == *.* ]]; then ext="${name##*.}"; else ext=""; fi
	folder="$(folder_for "$ext")"
	dest_dir="$TARGET/$folder"
	counts[$folder]=$(( ${counts[$folder]:-0} + 1 ))
	if (( GO )); then
		mkdir -p "$dest_dir"
		dest="$(free_name "$dest_dir" "$name")"
		mv -n -- "$path" "$dest"
		echo "moved  $name  ->  $folder/$(basename "$dest")"
	else
		echo "would move  $name  ->  $folder/"
	fi
done

echo
if (( ${#counts[@]} == 0 )); then
	echo "No loose files at the top of the drive; nothing to do."
	exit 0
fi
echo "Summary:"
for folder in "${!counts[@]}"; do printf '  %-15s %s file(s)\n' "$folder" "${counts[$folder]}"; done
(( GO )) || echo -e "\nLooks right? Run again with --go to move them."
