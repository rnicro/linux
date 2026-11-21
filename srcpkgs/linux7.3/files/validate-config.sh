#!/bin/sh
set -eu

config=${1:-.config}
[ -r "$config" ] || { echo "Kernel config not found: $config" >&2; exit 1; }

require_value() {
    symbol="$1"
    value="$2"
    if ! grep -Fqx "CONFIG_${symbol}=${value}" "$config"; then
        echo "Required kernel option is not CONFIG_${symbol}=${value}" >&2
        grep -E "^(CONFIG_${symbol}=|# CONFIG_${symbol} is not set)" "$config" >&2 || true
        exit 1
    fi
}

require_disabled() {
    symbol="$1"
    # Hidden Kconfig symbols can be omitted from .config entirely when their
    # parent dependency is disabled. Treat absence as n; reject y or m.
    if grep -Eq "^CONFIG_${symbol}=(y|m|[1-9])" "$config"; then
        echo "CONFIG_${symbol} must be disabled" >&2
        grep -E "^(CONFIG_${symbol}=|# CONFIG_${symbol} is not set)" "$config" >&2 || true
        exit 1
    fi
}

# Built-in storage/filesystem path keeps the ext4 root disk available at boot.
for symbol in X86_64 MODULES BLK_DEV_INITRD EFI EXT4_FS ATA SCSI BLK_DEV_SD SATA_AHCI ACPI SUSPEND; do
    require_value "$symbol" y
done

# Hardware drivers expected on the HP Pavilion x360 T0Y58PA.
for symbol in DRM_I915 IWLWIFI IWLMVM R8169 MISC_RTSX_PCI MMC_REALTEK_PCI \
              BT BT_HCIBTUSB BT_INTEL SND_HDA_INTEL SND_SOC_SOF_INTEL_SKL \
              USB_XHCI_HCD USB_XHCI_PCI USB_VIDEO_CLASS HID_MULTITOUCH \
              HID_ELAN MOUSE_PS2 HP_WMI HP_ACCEL HID_SENSOR_HUB \
              HID_SENSOR_CUSTOM_INTEL_HINGE INTEL_ISH_HID; do
    require_value "$symbol" m
done

# Explicitly excluded features.
for symbol in IA32_EMULATION X86_X32_ABI HIBERNATION KVM VFIO VHOST VHOST_NET \
              VHOST_SCSI VHOST_VSOCK VHOST_VDPA VIRTIO HYPERVISOR_GUEST HYPERV \
              XEN DRM_I915_GVT DRM_I915_GVT_KVMGT; do
    require_disabled "$symbol"
done

echo "Kernel configuration validation passed."
