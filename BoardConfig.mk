#
# Copyright (C) 2024 The Android Open Source Project
#
# SPDX-License-Identifier: Apache-2.0
#

DEVICE_PATH := device/nothing/Tetris
KERNEL_PATH := device/nothing/Tetris/prebuilt

# For building with minimal manifest
ALLOW_MISSING_DEPENDENCIES := true

# A/B
AB_OTA_UPDATER := true
AB_OTA_PARTITIONS += \
    system_dlkm \
    vendor \
    odm \
    system \
    boot \
    vbmeta_system \
    odm_dlkm \
    product \
    vbmeta_vendor \
    vendor_dlkm \
    system_ext \
    vendor_boot \
    dtbo \
    init_boot

# Architecture
TARGET_ARCH := arm64
# FIX (Session 10): found missing via duchamp comparison. BOARD_HAS_MTK_HARDWARE
# likely gates MTK-specific code paths in OrangeFox core source.
TARGET_USES_64_BIT_BINDER := true
BOARD_HAS_MTK_HARDWARE := true
TARGET_ARCH_VARIANT := armv8-a
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_ABI2 :=
TARGET_CPU_VARIANT := generic
TARGET_CPU_VARIANT_RUNTIME := cortex-a55

TARGET_2ND_ARCH := arm
TARGET_2ND_ARCH_VARIANT := armv7-a-neon
TARGET_2ND_CPU_ABI := armeabi-v7a
TARGET_2ND_CPU_ABI2 := armeabi
TARGET_2ND_CPU_VARIANT := generic
TARGET_2ND_CPU_VARIANT_RUNTIME := cortex-a55

# APEX
OVERRIDE_TARGET_FLATTEN_APEX := true

# Bootloader
TARGET_BOOTLOADER_BOARD_NAME := Tetris
TARGET_NO_BOOTLOADER := true

# Resolution
TARGET_SCREEN_HEIGHT := 2400
TARGET_SCREEN_WIDTH := 1080

# Display
TARGET_SCREEN_DENSITY := 420

# Debug
TWRP_INCLUDE_LOGCAT := true
TWRP_USES_LOGD := true

# Kernel
TARGET_KERNEL_ARCH := arm64
BOARD_RAMDISK_USE_LZ4 := true
TARGET_KERNEL_HEADER_ARCH := arm64
BOARD_BOOT_HEADER_VERSION := 4
BOARD_INIT_BOOT_HEADER_VERSION := 4
BOARD_INCLUDE_DTB_IN_BOOTIMG := true
BOARD_KERNEL_SEPARATED_DTBO := true
BOARD_KERNEL_IMAGE_NAME := Image.gz
BOARD_USES_GENERIC_KERNEL_IMAGE := true
BOARD_KERNEL_BASE := 0x3FFF8000
BOARD_PAGE_SIZE := 4096
BOARD_KERNEL_OFFSET := 0x00008000
BOARD_RAMDISK_OFFSET := 0x26F08000
BOARD_TAGS_OFFSET := 0x07C88000
BOARD_DTB_SIZE := 340109
BOARD_DTB_OFFSET := 0x07C88000
BOARD_VENDOR_CMDLINE := bootopt=64S3,32N2,64N2

BOARD_MKBOOTIMG_ARGS += --vendor_cmdline $(BOARD_VENDOR_CMDLINE)
BOARD_MKBOOTIMG_ARGS += --pagesize $(BOARD_PAGE_SIZE) --board ""
BOARD_MKBOOTIMG_ARGS += --kernel_offset $(BOARD_KERNEL_OFFSET)
BOARD_MKBOOTIMG_ARGS += --ramdisk_offset $(BOARD_RAMDISK_OFFSET)
BOARD_MKBOOTIMG_ARGS += --tags_offset $(BOARD_TAGS_OFFSET)
BOARD_MKBOOTIMG_ARGS += --header_version $(BOARD_BOOT_HEADER_VERSION)
BOARD_MKBOOTIMG_ARGS += --dtb_offset $(BOARD_DTB_OFFSET)

TARGET_NO_KERNEL_OVERRIDE := true
TARGET_PREBUILT_KERNEL := $(DEVICE_PATH)/prebuilt/kernel
BOARD_PREBUILT_DTBOIMAGE := $(DEVICE_PATH)/prebuilt/dtbo.img
BOARD_PREBUILT_DTBIMAGE_DIR := $(DEVICE_PATH)/prebuilt/dtb

# Load vendor_dlkm modules
BOARD_VENDOR_KERNEL_MODULES_LOAD := $(strip $(shell cat $(KERNEL_PATH)/modules/modules.load))
BOARD_VENDOR_KERNEL_MODULES := $(sort $(addprefix $(KERNEL_PATH)/modules/vendor_dlkm/, \
    $(notdir $(BOARD_VENDOR_KERNEL_MODULES_LOAD))))

# Load vendor_boot modules
BOARD_VENDOR_RAMDISK_KERNEL_MODULES_LOAD := $(strip $(shell cat $(KERNEL_PATH)/modules/modules.load.vendor_boot))
BOARD_VENDOR_RAMDISK_KERNEL_MODULES := $(sort $(addprefix $(KERNEL_PATH)/modules/vendor_boot/, \
    $(notdir $(BOARD_VENDOR_RAMDISK_KERNEL_MODULES_LOAD))))

# Load recovery modules (also from vendor_boot)
BOARD_VENDOR_RAMDISK_RECOVERY_KERNEL_MODULES_LOAD := $(strip $(shell cat $(KERNEL_PATH)/modules/modules.load.recovery))
BOARD_VENDOR_RAMDISK_RECOVERY_KERNEL_MODULES := $(addprefix $(KERNEL_PATH)/modules/vendor_boot/, \
    $(notdir $(BOARD_VENDOR_RAMDISK_RECOVERY_KERNEL_MODULES_LOAD)))

# Append recovery modules if they're not already in vendor_boot
BOARD_VENDOR_RAMDISK_KERNEL_MODULES += $(filter-out $(BOARD_VENDOR_RAMDISK_KERNEL_MODULES), \
    $(BOARD_VENDOR_RAMDISK_RECOVERY_KERNEL_MODULES))

# Partitions
BOARD_FLASH_BLOCK_SIZE := 262144 # (BOARD_KERNEL_PAGESIZE * 64)
BOARD_BOOTIMAGE_PARTITION_SIZE := 67108864
BOARD_VENDOR_BOOTIMAGE_PARTITION_SIZE := 67108864
BOARD_HAS_LARGE_FILESYSTEM := true
# FIX: was ext4/ext4, which contradicted recovery.fstab (erofs/f2fs) and
# the real stock partition layout. Aligned to match actual hardware.
BOARD_SYSTEMIMAGE_PARTITION_TYPE := erofs
BOARD_USERDATAIMAGE_FILE_SYSTEM_TYPE := f2fs
BOARD_VENDORIMAGE_FILE_SYSTEM_TYPE := erofs
# FIX (Session 10): found completely missing via duchamp comparison — the
# build system needs these to know how to construct product/vendor_dlkm/
# odm_dlkm partition images at all. Filesystem types set to erofs to match
# our own already-verified real device data (fstab.mt6878), not blindly
# copied from duchamp's own device-specific values.
BOARD_PRODUCTIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_VENDOR_DLKMIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_ODM_DLKIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_USES_VENDOR_DLKMIMAGE := true
BOARD_USES_ODM_DLKIMAGE := true
TARGET_COPY_OUT_PRODUCT := product
TARGET_COPY_OUT_VENDOR_DLKM := vendor_dlkm
TARGET_COPY_OUT_ODM_DLKM := odm_dlkm
TARGET_USES_PREBUILT_DYNAMIC_PARTITIONS := true
TW_NO_LEGACY_PARTITIONS := true
TARGET_USES_LOGD := true
BOARD_SUPPRESS_SECURE_ERASE := true
TARGET_COPY_OUT_VENDOR := vendor
BOARD_SUPER_PARTITION_SIZE := 9663676416
BOARD_SUPER_PARTITION_GROUPS := nothing_dynamic_partitions
BOARD_NOTHING_DYNAMIC_PARTITIONS_PARTITION_LIST := system system_ext vendor product odm vendor_dlkm odm_dlkm
BOARD_NOTHING_DYNAMIC_PARTITIONS_SIZE := 9122611200

# Properties
TARGET_SYSTEM_PROP += $(DEVICE_PATH)/system.prop

# Hardware
BOARD_USES_MTK_HARDWARE := true

# Platform
TARGET_BOARD_PLATFORM := mt6878

# Recovery
TARGET_RECOVERY_PIXEL_FORMAT := RGBX_8888
TARGET_USERIMAGES_USE_EXT4 := true
TARGET_USERIMAGES_USE_F2FS := true
TARGET_RECOVERY_FSTAB := $(DEVICE_PATH)/recovery/root/recovery.fstab
# FIX (Session 10): sepolicy directory was completely missing. Added via
# comparison with a real, genuinely MediaTek Android-16 device (duchamp,
# POCO X6 Pro) whose maintainer's own comments describe these rules as
# the fix for FBE decrypt keystore access — directly relevant to our own
# decrypt struggles, and plausibly to the still-unresolved "bootctrl
# module" error too (several rules concern service_manager registration).
# These are additive "allow" rules only — low risk, can't break anything
# that already worked.
BOARD_RECOVERY_SEPOLICY_DIRS += $(LOCAL_PATH)/sepolicy

# Security patch level
# (duplicate VENDOR_SECURITY_PATCH removed here — was set twice with two
# different values; the intentional anti-rollback value below is the one
# that actually takes effect in make anyway, this just removes the confusing
# dead duplicate)

# Verified Boot
BOARD_AVB_ENABLE := true
# FIX (Session 9): AVB recovery signing params were missing — standard AOSP
# test key path, universal across virtually every custom recovery build.
BOARD_AVB_RECOVERY_KEY_PATH := external/avb/test/data/testkey_rsa4096.pem
BOARD_AVB_RECOVERY_ALGORITHM := SHA256_RSA4096
BOARD_AVB_RECOVERY_ROLLBACK_INDEX := 1
BOARD_AVB_RECOVERY_ROLLBACK_INDEX_LOCATION := 1
BOARD_AVB_MAKE_VBMETA_IMAGE_ARGS += --flags 3

# Hack: prevent anti rollback
PLATFORM_SECURITY_PATCH := 2099-12-31
VENDOR_SECURITY_PATCH := 2099-12-31
PLATFORM_VERSION := 16.1.0

# TWRP Configuration
# FIX: TW_INCLUDE_CRYPTO_FBE / TW_INCLUDE_FBE_METADATA_DECRYPT were
# completely missing. Verified against multiple real, official OrangeFox
# device trees (including OrangeFoxRecovery's own device_xiaomi_spes) —
# these are explicitly set per-device, never silently inherited. Without
# them, the decrypt code path isn't compiled into the recovery binary at
# all, regardless of how correct recovery.fstab's flags are. Deliberately
# NOT adding BOARD_USES_QCOM_FBE_DECRYPTION — that's Qualcomm-specific and
# would be wrong here (this is MediaTek).
TW_INCLUDE_CRYPTO := true
TW_INCLUDE_CRYPTO_FBE := true
TW_INCLUDE_FBE_METADATA_DECRYPT := true
BOARD_USES_METADATA_PARTITION := true
# FIX (Session 8): found via OrangeFox's own official MediaTek device-tree
# guide (gist.github.com/lopestom). TW_USE_FSCRYPT_POLICY is evidenced
# directly by our real fstab.mt6878's fileencryption= value containing
# "v2" (aes-256-cts:v2+inlinecrypt_optimized) — policy version 2, not the
# default guess. TW_PREPARE_DATA_MEDIA_EARLY is documented to resolve
# decrypt issues on some devices.
TW_USE_FSCRYPT_POLICY := 2
TW_PREPARE_DATA_MEDIA_EARLY := true
TARGET_RECOVERY_DEVICE_MODULES += libkeymaster4
TW_RECOVERY_ADDITIONAL_RELINK_LIBRARY_FILES += $(TARGET_OUT_SHARED_LIBRARIES)/libkeymaster4.so
BOARD_ROOT_EXTRA_FOLDERS += metadata
TW_HAS_MTP := false
TW_THEME := portrait_hdpi
TW_EXTRA_LANGUAGES := true
# FIX (Session 9): found via marble comparison. TW_EXCLUDE_DEFAULT_USB_INIT
# avoids TWRP's own default USB init logic potentially conflicting with the
# custom sys.usb.configfs/controller setprop lines already in
# init.recovery.mt6878.rc. TW_NO_EXFAT_FUSE gives native exFAT support
# (relevant since we have USB-OTG storage support).
TW_EXCLUDE_DEFAULT_USB_INIT := true
TW_NO_EXFAT_FUSE := true
TW_NO_CPU_TEMP := true
TW_USE_LEGACY_BATTERY_SERVICES := true
# TW_INPUT_BLACKLIST := "hbtp_vm" # disabled: hbtp_vm may be the touchscreen input
TW_USE_TOOLBOX := true
TW_INCLUDE_REPACKTOOLS := true
TW_MAX_BRIGHTNESS := 2047
# FIX: TW_SCREEN_BLANK_ON_BOOT was duplicated (also set at line 159 above),
# and it directly conflicts with TW_NO_SCREEN_BLANK below (one blanks the
# screen on boot, the other disables blanking). Keeping TW_NO_SCREEN_BLANK
# only, since that's almost always what's actually wanted on a device
# that's already had display/backlight bring-up issues.
TW_NO_SCREEN_BLANK := true
TW_CUSTOM_BATTERY_PATH := "/sys/class/power_supply/battery"
TW_Y_OFFSET := 95
TW_H_OFFSET := -95

# include python, for ABX conversion
TW_INCLUDE_PYTHON := true

# Modules
TW_LOAD_VENDOR_MODULES_EXCLUDE_GKI := true

# Vendor_boot recovery ramdisk
BOARD_USES_RECOVERY_AS_BOOT := false
# (duplicate BOARD_USES_GENERIC_KERNEL_IMAGE removed — already set above near kernel config)
BOARD_MOVE_RECOVERY_RESOURCES_TO_VENDOR_BOOT := true
BOARD_EXCLUDE_KERNEL_FROM_RECOVERY_IMAGE :=
BOARD_MOVE_GSI_AVB_KEYS_TO_VENDOR_BOOT :=
TW_LOAD_VENDOR_BOOT_MODULES := true
BOARD_INCLUDE_RECOVERY_RAMDISK_IN_VENDOR_BOOT := true

