#!/bin/sh
set -eu

dist=${1:-dist}
: "${GH_TOKEN:?GH_TOKEN is required}"
: "${GH_REPO:?GH_REPO is required}"
: "${VERSION:?VERSION is required}"
: "${REVISION:?REVISION is required}"
: "${TAG:?TAG is required}"

set -- "$dist"/linux7.3-"${VERSION}"_"${REVISION}".x86_64-musl.xbps \
       "$dist"/linux7.3-headers-"${VERSION}"_"${REVISION}".x86_64-musl.xbps
[ -s "$1" ] && [ -s "$2" ] || {
    echo "Expected kernel and headers packages were not found in $dist" >&2
    exit 1
}

if gh release view "$TAG" --repo "$GH_REPO" >/dev/null 2>&1; then
    tmp="$(mktemp -d)"
    trap 'rm -rf "$tmp"' EXIT HUP INT TERM
    gh release download "$TAG" --repo "$GH_REPO" --dir "$tmp"
    for package in "$@"; do
        asset="$tmp/$(basename "$package")"
        if [ ! -s "$asset" ] || ! cmp -s "$package" "$asset"; then
            echo "Release $TAG already exists with different package bytes." >&2
            echo "Increment revision in srcpkgs/linux7.3/template before publishing changed output." >&2
            exit 1
        fi
    done
    echo "Release $TAG already contains identical kernel and headers packages."
    exit 0
fi

notes="$(cat <<EOF
Linux ${VERSION}-${REVISION} for the HP Pavilion x360 Convertible T0Y58PA.

Target:
- Intel Core i3-6100U (Skylake), x86_64-musl
- GCC kernel build using -march=skylake -mtune=skylake
- Built on GitHub Actions; not compiled on the target laptop

Kernel configuration:
- Device-focused Intel graphics, Wi-Fi, Bluetooth, audio, Ethernet, touchscreen, touchpad, webcam and card-reader support
- SATA/AHCI and ext4 built into the kernel for the root filesystem
- 32-bit compatibility, hibernation and virtualization support disabled
- Suspend/resume retained; drivers are modules where practical

Packages:
- linux7.3-${VERSION}_${REVISION}.x86_64-musl.xbps
- linux7.3-headers-${VERSION}_${REVISION}.x86_64-musl.xbps

This kernel is optimized for Intel Skylake and is not intended for older x86_64 CPUs. Firmware remains supplied by Void Linux firmware packages. Keep a known-good kernel installed until the new kernel has booted and all laptop devices have been tested.
EOF
)"

gh release create "$TAG" "$@" --repo "$GH_REPO" \
    --title "Linux ${VERSION}-${REVISION} for HP Pavilion x360" \
    --notes "$notes"
