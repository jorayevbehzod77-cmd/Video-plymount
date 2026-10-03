#!/usr/bin/env bash
set -euo pipefail

if (( EUID != 0 )); then
  printf 'Run this script with sudo.\n' >&2
  exit 1
fi

source_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
config_source="$source_dir/90-custom-video-boot.conf"
config_target=/etc/dracut.conf.d/90-custom-video-boot.conf
initrd="/boot/initrd.img-$(uname -r)"
theme_script=/usr/share/plymouth/themes/custom-video-boot/custom-video-boot.script

if [[ ! -f "$theme_script" ]] || ! grep -qx 'Theme=custom-video-boot' /etc/plymouth/plymouthd.conf; then
  printf 'The custom-video-boot theme is not active; stopped.\n' >&2
  exit 1
fi
if ! grep -Fq 'if dracut ' /usr/sbin/update-initramfs; then
  printf 'This system is no longer using dracut through update-initramfs; stopped.\n' >&2
  exit 1
fi
if [[ ! -w /etc/dracut.conf.d ]] || [[ ! -w /boot ]] || ! modinfo -n i915 >/dev/null; then
  printf 'Cannot write dracut/boot files or locate i915; stopped.\n' >&2
  exit 1
fi
if [[ -e "$config_target" ]] && ! cmp -s "$config_source" "$config_target"; then
  printf '%s already exists with different content; stopped.\n' "$config_target" >&2
  exit 1
fi

backup="$(mktemp /var/backups/custom-video-boot-initrd.XXXXXX)"
cp -a "$initrd" "$backup"
created_config=0
if [[ ! -e "$config_target" ]]; then
  install -m 0644 "$config_source" "$config_target"
  created_config=1
fi

manifest="$(mktemp /tmp/custom-video-boot-initrd.XXXXXX)"
trap 'rm -f -- "$manifest"' EXIT
error=
if ! update-initramfs -u -k "$(uname -r)"; then
  error='The initramfs rebuild failed.'
elif ! lsinitramfs "$initrd" > "$manifest"; then
  error='The rebuilt initramfs could not be listed.'
elif ! grep -F 'custom-video-boot/custom-video-boot.script' "$manifest" >/dev/null; then
  error='The custom Plymouth theme is missing from the rebuilt initramfs.'
elif [[ -f /usr/share/plymouth/themes/custom-video-boot/boot-180.png ]] &&
     ! grep -F 'custom-video-boot/boot-180.png' "$manifest" >/dev/null; then
  error='The last boot frame is missing from the rebuilt initramfs.'
elif ! grep -E '(^|/)i915\.ko(\.|$)' "$manifest" >/dev/null; then
  error='The i915 driver is missing from the rebuilt initramfs.'
fi

if [[ -n "$error" ]]; then
  cp -a "$backup" "$initrd"
  if (( created_config )); then rm -f -- "$config_target"; fi
  printf '%s The previous boot image was restored from %s\n' "$error" "$backup" >&2
  exit 1
fi

old_modules=/var/backups/initramfs-modules.20261003-152814.24752
current_modules=/etc/initramfs-tools/modules
if [[ -f "$old_modules" ]] && cmp -s "$current_modules" <(cat "$old_modules"; printf '\ni915\n'); then
  cp -a "$old_modules" "$current_modules"
fi

printf 'Verified: custom theme and i915 are in %s\n' "$initrd"
printf 'Previous boot image saved at %s\n' "$backup"
