# Linux 7.3 for HP Pavilion x360

A hardware-specific Linux kernel package for the HP Pavilion x360 Convertible T0Y58PA, targeting Void Linux `x86_64-musl`.

## Target hardware

- Intel Core i3-6100U (Skylake, 2 cores / 4 threads)
- Intel HD Graphics 520
- Intel Wireless 3165 and Intel Bluetooth
- Realtek RTL810xE Ethernet
- Intel Sunrise Point-LP HDA / Skylake SOF audio
- ELAN touchscreen and stylus; Synaptics touchpad
- HP webcam, USB 3.x and Realtek RTS522A SD card reader
- SATA HDD, ext4 root filesystem, UEFI and GRUB

## Build

GitHub Actions builds the Void XBPS package on an Ubuntu-hosted runner. The runner is only the build host; kernel code is compiled for the target device.

The Void Linux `linux7.3` package recipe is used as the packaging baseline. The workflow overlays this repository's package recipe and custom x86_64 configuration into `void-packages`, bootstraps `x86_64-musl`, and builds the kernel and headers packages.

### Skylake tuning

Kernel C compilation uses:

```sh
KCFLAGS="-march=skylake -mtune=skylake"
```

These flags target the Intel Core i3-6100U, not the GitHub Actions runner. This kernel is not intended for pre-Skylake x86_64 processors. The compiler is GCC; the host runner's CPU does not determine the target instruction set.

## Configuration choices

- x86_64 only; 32-bit and x32 userspace compatibility disabled
- SATA/AHCI, SCSI disk support and ext4 built into the kernel
- Intel i915, iwlwifi, Bluetooth, Realtek Ethernet, audio, USB, ELAN, Synaptics, HP WMI and sensor drivers enabled as modules where practical
- Suspend/resume retained; hibernation disabled
- KVM, VFIO, vhost, virtio, Xen and Hyper-V guest support disabled
- General namespaces and cgroups are retained to avoid breaking ordinary userspace services
- Firmware is not bundled in the kernel packages; install Void's relevant `linux-firmware` packages and Intel microcode separately

## Releases

Successful builds from `main` publish versioned GitHub Releases containing:

- `linux7.3-<version>_<revision>.x86_64-musl.xbps`
- `linux7.3-headers-<version>_<revision>.x86_64-musl.xbps`

The debug-symbol subpackage is not published. Packaging changes that alter package bytes require incrementing `revision` in `srcpkgs/linux7.3/template`.

## Installing

Download both XBPS files from the same release. Install them locally with XBPS, then let Void's kernel hooks and dracut regenerate the initramfs and boot entries as configured on the system.

Keep the existing working kernel installed until the new kernel has booted successfully and graphics, networking, audio, touchscreen, touchpad, webcam, suspend/resume and SD card access have been tested.

## Maintenance

When updating the kernel version, update the source version and checksums in `srcpkgs/linux7.3/template`, refresh the base configuration against the matching Void package, and test the complete XBPS build before publishing.
