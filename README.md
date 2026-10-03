# Video Plymouth theme

A custom Plymouth theme with a curtain-opening boot animation and a separate
curtain-closing animation for shutdown and reboot. The boot sequence is about
six seconds at 30 FPS. Its opening frames are motion-interpolated from the
original clip, with repeated poses removed to avoid visible pauses. The
animation fits a centered 736x414 canvas on a black background without
changing the image's aspect ratio.

[Preview the boot sequence](boot-preview-smooth.mp4)

## Scope

This is a backup of a theme configured for one Ubuntu laptop with Intel i915
graphics, Plymouth's script plugin, and a dracut-based initramfs. It is not a
universal installer. In particular, the installer expects an existing active
`custom-video-boot` theme and will stop if that condition is not met. Review
the scripts before using them on another machine.

The original source video is not included. `custom-video-boot.zip` contains
the optimized image sequences used by Plymouth: 181 boot frames and 18
shutdown frames, each 316x414 pixels.

## Update this setup

From the repository directory on the configured laptop:

```bash
unzip custom-video-boot.zip
sudo bash ./install-custom-video-boot.sh
```

The installer backs up the current theme, rebuilds the initramfs, and checks
that the theme and i915 driver are present. If rebuilding or verification
fails, it restores the previous theme and boot image. It does not edit GRUB
or add systemd units.

The shutdown sequence uses the closing motion from the source video. After
the boot sequence finishes, only the open-scene motion loops; the curtain
does not reopen.
