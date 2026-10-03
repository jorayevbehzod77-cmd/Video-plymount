#!/usr/bin/env bash
set -euo pipefail

if (( EUID != 0 )); then
  printf 'Run this installer with sudo.\n' >&2
  exit 1
fi

source_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/custom-video-boot" && pwd)"
output_dir="$(dirname -- "$source_dir")"
target=/usr/share/plymouth/themes/custom-video-boot

if [[ ! -d "$target" ]] || ! grep -qx 'Theme=custom-video-boot' /etc/plymouth/plymouthd.conf; then
  printf 'The expected custom-video-boot theme is no longer active; installation stopped.\n' >&2
  exit 1
fi

if [[ ! -w /usr/share/plymouth/themes ]]; then
  printf 'The system filesystem is read-only; installation stopped.\n' >&2
  exit 1
fi

if [[ $(find "$source_dir" -maxdepth 1 -name 'boot-*.png' | wc -l) -ne 181 ]] ||
   [[ $(find "$source_dir" -maxdepth 1 -name 'shutdown-*.png' | wc -l) -ne 18 ]]; then
  printf 'The boot or shutdown frame sequence is incomplete; installation stopped.\n' >&2
  exit 1
fi

staging="$(mktemp -d /usr/share/plymouth/themes/.custom-video-boot.new.XXXXXX)"
cp -a "$source_dir/." "$staging/"
chown -R root:root "$staging"
chmod 755 "$staging"
find "$staging" -type f -exec chmod 644 {} +

backup="/var/backups/custom-video-boot.$(date +%Y%m%d-%H%M%S).$$"
mv "$target" "$backup"
if ! mv "$staging" "$target"; then
  mv "$backup" "$target"
  printf 'Could not put the replacement theme in place. The original was restored.\n' >&2
  exit 1
fi

if ! bash "$output_dir/finish-early-graphics.sh"; then
  failed="/var/backups/custom-video-boot.failed.$(date +%Y%m%d-%H%M%S).$$"
  mv "$target" "$failed"
  mv "$backup" "$target"
  printf 'The original theme was restored; replacement saved at %s\n' "$failed" >&2
  exit 1
fi

printf 'Installed. Original theme saved at %s\n' "$backup"
printf 'Boot: 181 frames at 30 FPS, then loop open-scene motion. Shutdown/reboot: 18 frames at 30 FPS, then hold black.\n'
