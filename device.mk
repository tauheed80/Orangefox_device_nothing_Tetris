DEVICE_PATH := device/nothing/Tetris

# API
# VERIFIED against real firmware (boot.img kernel banner, vbmeta property
# descriptors, live device "Sakura" ROM info screen): this device is
# genuinely running Android 16 — os_version=16 confirmed on every
# partition's AVB descriptor, fingerprint Nothing/lineage_Tetris/Tetris:16.
# Real Android-16 vendor blobs exist and boot successfully on this exact
# hardware, so this is no longer a guess.
PRODUCT_SHIPPING_API_LEVEL := 36
# FIX (Session 9): real reference trees set all 4 of these together to the
# same value — we only had PRODUCT_SHIPPING_API_LEVEL.
BOARD_SHIPPING_API_LEVEL := 36
BOARD_API_LEVEL := 36
SHIPPING_API_LEVEL := 36
PRODUCT_TARGET_VNDK_VERSION := 36

# A/B
AB_OTA_UPDATER := true
AB_OTA_PARTITIONS += \
    boot \
    product \
    system \
    system_ext \
    vendor 
  
PRODUCT_PACKAGES += \
    update_engine \
    update_engine_client \
    update_engine_sideload \
    update_verifier \
    otapreopt_script \
    checkpoint_gc

# FIX (Session 9): found missing via comparison with a real working tree
PRODUCT_SOONG_NAMESPACES += \
    $(DEVICE_PATH)

AB_OTA_POSTINSTALL_CONFIG += \
    RUN_POSTINSTALL_system=true \
    POSTINSTALL_PATH_system=system/bin/otapreopt_script \
    FILESYSTEM_TYPE_system=$(BOARD_SYSTEMIMAGE_FILE_SYSTEM_TYPE) \
    POSTINSTALL_OPTIONAL_system=true

AB_OTA_POSTINSTALL_CONFIG += \
    RUN_POSTINSTALL_vendor=true \
    POSTINSTALL_PATH_vendor=bin/checkpoint_gc \
    FILESYSTEM_TYPE_vendor=$(BOARD_VENDORIMAGE_FILE_SYSTEM_TYPE) \
    POSTINSTALL_OPTIONAL_vendor=true

# Additional Target Libraries
TARGET_RECOVERY_DEVICE_MODULES += \
    android.hardware.graphics.common@1.0 \
    libion \
    libxml2

TW_RECOVERY_ADDITIONAL_RELINK_LIBRARY_FILES += \
    $(TARGET_OUT_SHARED_LIBRARIES)/android.hardware.graphics.common@1.0.so \
    $(TARGET_OUT_SHARED_LIBRARIES)/libion.so \
    $(TARGET_OUT_SHARED_LIBRARIES)/libxml2.so

# Bootctrl
PRODUCT_PACKAGES += \
    android.hardware.boot@1.2-service \
    android.hardware.boot@1.2-mtkimpl \
    android.hardware.boot@1.2-mtkimpl.recovery

PRODUCT_PACKAGES_DEBUG += \
    bootctrl

# Dynamic
PRODUCT_USE_DYNAMIC_PARTITIONS := true

# DRM
PRODUCT_PACKAGES += \
    android.hardware.drm@1.4

# Health
PRODUCT_PACKAGES += \
    android.hardware.health@2.1-impl \
    android.hardware.health@2.1-service

# MTK plpath utils
PRODUCT_PACKAGES += \
    mtk_plpath_utils \
    mtk_plpath_utils.recovery

# HIDL Service
PRODUCT_ENFORCE_VINTF_MANIFEST := true

# Recovery init
# FIX: was "mt6886.rc" (the marketing chip number, Dimensity 7300) — that
# file doesn't exist anywhere in this tree. The real internal platform
# code, confirmed throughout via fstab.mt6878, ro.boot.hardware=mt6878,
# etc., is mt6878 — and that's the actual filename in recovery/root/.
PRODUCT_PACKAGES += \
    init.recovery.mt6878.rc

# Filesystem table
PRODUCT_PACKAGES += \
    recovery.fstab \

# fastbootd
PRODUCT_PACKAGES += \
    fastbootd

# Gatekeeper
PRODUCT_PACKAGES += \
	android.hardware.gatekeeper@1.0-service

# Additional Libraries
TARGET_RECOVERY_DEVICE_MODULES += \
    libkeymaster4 \
    libkeymaster41 \
    libpuresoftkeymasterdevice

RECOVERY_LIBRARY_SOURCE_FILES += \
    $(TARGET_OUT_SHARED_LIBRARIES)/libkeymaster4.so \
    $(TARGET_OUT_SHARED_LIBRARIES)/libkeymaster41.so \
    $(TARGET_OUT_SHARED_LIBRARIES)/libpuresoftkeymasterdevice.so

# Rootdir
PRODUCT_PACKAGES += \
    servicemanager.recovery.rc \
    snapuserd.rc
