#
# Copyright (C) 2026 The Android Open Source Project
#
# SPDX-License-Identifier: Apache-2.0
#
# 小米平板 6 Max 14（yudi, 2307BRPDCC）板级配置 —— YARP / TWRP 16 版
#
# 数值来源（全部经真机核对）：
#   真机        /dev/block/by-name 分区表、blockdev --getsize64、/vendor/etc/fstab.qcom
#   真机        getprop / wm size / /sys/class/thermal、/sys/class/backlight
#   boot.img    magiskboot unpack：HEADER_VER 4 / KERNEL_SZ 41750964 / PAGESIZE 4096 /
#               OS_VERSION 12.0.0 / OS_PATCH_LEVEL 2025-09 / RAMDISK_FMT lz4_legacy
#   OF 树       OneFeiFan/device_xiaomi_yudi（OrangeFox 已验证可启动）的板级结论
#

DEVICE_PATH := device/xiaomi/yudi

# 构建系统最小化（YARP 约定）
ALLOW_MISSING_DEPENDENCIES := true

# 设备断言：安装 zip 时校验 ro.product.device，避免误刷到 liuqin 等其他机型
TARGET_OTA_ASSERT_DEVICE := yudi

# 额外系统属性
TARGET_SYSTEM_PROP += $(DEVICE_PATH)/system.prop

# Rules
BUILD_BROKEN_DUP_RULES := true
BUILD_BROKEN_ELF_PREBUILT_PRODUCT_COPY_FILES := true

# 架构：骁龙 8+ Gen 1（SM8475），taro 平台
TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-2a-dotprod
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_ABI2 :=
TARGET_CPU_VARIANT := generic

# Bootloader
# 真机 ro.board.platform=taro，ro.boot.hardware.platform 为空，ro.boot.hardware=qcom
PRODUCT_PLATFORM := taro
TARGET_BOOTLOADER_BOARD_NAME := $(PRODUCT_PLATFORM)
TARGET_NO_BOOTLOADER := true
QCOM_BOARD_PLATFORMS += taro

# Platform
TARGET_BOARD_PLATFORM := taro
TARGET_BOARD_PLATFORM_GPU := qcom-adreno730

# 内核
# 原厂 recovery.img 头部 kernel_size = 0：恢复镜像本身不带内核，bootloader 复用 boot
# 分区的内核。因此 prebuilt/kernel 是 0 字节占位，只用于满足构建系统对
# TARGET_PREBUILT_KERNEL 文件存在的检查，实际不会打进镜像。
TARGET_KERNEL_ARCH := arm64
TARGET_KERNEL_HEADER_ARCH := arm64
TARGET_KERNEL_VERSION := 5.10
BOARD_KERNEL_PAGESIZE := 4096
TARGET_FORCE_PREBUILT_KERNEL := true
TARGET_PREBUILT_KERNEL := $(DEVICE_PATH)/prebuilt/kernel
BOARD_EXCLUDE_KERNEL_FROM_RECOVERY_IMAGE := true

BOARD_KERNEL_IMAGE_NAME := Image
BOARD_BOOT_HEADER_VERSION := 4
BOARD_MKBOOTIMG_ARGS += --header_version $(BOARD_BOOT_HEADER_VERSION)
BOARD_MKBOOTIMG_ARGS += --pagesize $(BOARD_KERNEL_PAGESIZE)

# ramdisk 使用 LZ4（真机 boot/recovery 均为 lz4_legacy）
BOARD_RAMDISK_USE_LZ4 := true

# A/B
AB_OTA_UPDATER := true
AB_OTA_PARTITIONS += \
    boot \
    dtbo \
    odm \
    product \
    recovery \
    system \
    system_ext \
    vbmeta \
    vbmeta_system \
    vendor \
    vendor_boot \
    vendor_dlkm

# 分区大小（真机 blockdev 实测，与 OF 树一致）
BOARD_BOOTIMAGE_PARTITION_SIZE := 201326592
BOARD_VENDOR_BOOTIMAGE_PARTITION_SIZE := 100663296
BOARD_RECOVERYIMAGE_PARTITION_SIZE := 104857600
BOARD_DTBOIMG_PARTITION_SIZE := 25165824
BOARD_FLASH_BLOCK_SIZE := 262144

# 动态分区
# 实测 super 分区为 11811160064 字节，但 OTA 里 qti_dynamic_partitions 组的上限是
# 10 GiB。这里取分区组上限 + 4 MiB 元数据，仅用于构建期校验，不参与 recovery 产物。
# 注意：mi_ext 也属于该组，但构建系统不认识它，因此不列入；挂载交给 fstab。
BOARD_SUPER_PARTITION_SIZE := 10741612544
BOARD_SUPER_PARTITION_GROUPS := qti_dynamic_partitions
BOARD_QTI_DYNAMIC_PARTITIONS_SIZE := 10737418240
BOARD_QTI_DYNAMIC_PARTITIONS_PARTITION_LIST := \
    odm \
    product \
    system \
    system_ext \
    vendor \
    vendor_dlkm

# 文件系统：逻辑分区 erofs、userdata f2fs、metadata ext4（真机 fstab 实测）
BOARD_USES_METADATA_PARTITION := true
BOARD_USERDATAIMAGE_FILE_SYSTEM_TYPE := f2fs
BOARD_SYSTEMIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_SYSTEM_EXTIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_PRODUCTIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_VENDORIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_VENDOR_DLKMIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_ODMIMAGE_FILE_SYSTEM_TYPE := erofs
TARGET_COPY_OUT_SYSTEM_EXT := system_ext
TARGET_COPY_OUT_PRODUCT := product
TARGET_COPY_OUT_VENDOR := vendor
TARGET_COPY_OUT_VENDOR_DLKM := vendor_dlkm
TARGET_COPY_OUT_ODM := odm
TARGET_USERIMAGES_USE_EXT4 := true
TARGET_USERIMAGES_USE_F2FS := true
BOARD_HAS_LARGE_FILESYSTEM := true

# 恢复模式的显示和输入
TARGET_RECOVERY_PIXEL_FORMAT := RGBX_8888
TARGET_RECOVERY_QCOM_RTC_FIX := true
TARGET_RECOVERY_FSTAB := $(DEVICE_PATH)/recovery.fstab

# AVB：解锁状态下 recovery 不需要通过原厂校验，用 AOSP 测试密钥签名
BOARD_AVB_ENABLE := true
BOARD_AVB_RECOVERY_KEY_PATH := external/avb/test/data/testkey_rsa4096.pem
BOARD_AVB_RECOVERY_ALGORITHM := SHA256_RSA4096
BOARD_AVB_RECOVERY_ROLLBACK_INDEX := 1
BOARD_AVB_RECOVERY_ROLLBACK_INDEX_LOCATION := 1

# 版本号与安全补丁级别（**必须与当前 ROM 一致**）
# 厂商的 libqtikeymint/libqtikeymaster4 会读 ro.build.version.release、
# ro.build.version.security_patch 与 ro.vendor.build.security_patch，据此判断 metadata
# key 是否需要升级。写小了会一直返回 -62 KEY_REQUIRES_UPGRADE，而升级必然失败（-8），
# 表现为解密彻底不可用。
#
# 当前值取自真机（HyperOS OS4.0.6.0.XMHCNXM，Android 17）：
#   ro.build.version.release          = 17
#   ro.build.version.sdk              = 37
#   ro.build.version.security_patch   = 2026-10-01
#   ro.vendor.build.security_patch    = 2026-02-01
#   ro.vendor.build.version.release   = 12   （vendor 镜像仍按 12 构建）
#
# ROM 每次更新后都要重新核对，命令：
#   adb shell getprop ro.build.version.release
#   adb shell getprop ro.build.version.security_patch
#   adb shell getprop ro.vendor.build.security_patch
# 把下面的 PLATFORM_SECURITY_PATCH / BOOT_SECURITY_PATCH / PLATFORM_VERSION 改成新值再构建。
#
# boot 头部仍与原厂 boot 保持一致（12.0.0 / 2025-09），用 mkbootimg 参数显式覆盖。
PLATFORM_VERSION := 17
# LAST_STABLE 必须留给 16：它表示"本分支最近一个稳定版本"，会被 CTS 用来查
# cts/tests/tests/os/assets/platform_releases.txt，而本树基线是 android16.0.0_r1，
# 该文件里没有 "17" 条目。把它设成 17 会直接让 ckati 中止：
#   Could not find version "17" in CTS platform release file
# PLATFORM_VERSION（= ro.build.version.release）与 LAST_STABLE 是两件事：
# 前者要给 KeyMint 看（必须等于 ROM 的 17），后者只影响 CTS 与补丁级别推导。
PLATFORM_VERSION_LAST_STABLE := 16
PLATFORM_SECURITY_PATCH := 2026-10-01
VENDOR_SECURITY_PATCH := 2026-02-01
BOOT_SECURITY_PATCH := 2026-10-01
BOARD_MKBOOTIMG_ARGS += --os_version 12.0.0 --os_patch_level 2025-09

# 解密：FBE v2（inlinecrypt_optimized + wrappedkey_v0）加 metadata 加密
TW_INCLUDE_CRYPTO := true
TW_INCLUDE_CRYPTO_FBE := true
TW_INCLUDE_FBE_METADATA_DECRYPT := true
TW_USE_FSCRYPT_POLICY := 2
# 强制只用 keymaster_ver 属性，不从 vendor manifest 探测版本（本设备为 4.1）
TW_FORCE_KEYMASTER_VER := true
# 格式化 data 前先用 dmctl 解除 metadata 加密映射，否则 make_f2fs 报
# "In use by the system!"（物理 userdata 仍被 dm 占用）
TW_USE_DMCTL := true

# 界面
# 面板原生 2880x1800，系统用 ORIENTATION_270 作为自然方向；TWRP 只有竖屏界面，
# 同样旋转 270 度。四角实测无需 SWAP/FLIP 参数。
TW_THEME := portrait_hdpi
TW_ROTATION := 270
# 主题按 1080x1920 设计，屏幕 1800x2880：scale = 1.5，内容宽 1620px，左右各留 90px
TW_W_OFFSET := -180
TW_X_OFFSET := 90
TW_FRAMERATE := 60
TW_NO_SCREEN_BLANK := true
TW_STATUS_ICONS_ALIGN := center

# 背光：真机 /sys/class/backlight/panel0-backlight/max_brightness = 4095
TW_BRIGHTNESS_PATH := "/sys/class/backlight/panel0-backlight/brightness"
TW_MAX_BRIGHTNESS := 4095
TW_DEFAULT_BRIGHTNESS := 1200

# 语言
TW_DEFAULT_LANGUAGE := zh_CN
TW_EXTRA_LANGUAGES := true

# CPU 温度：taro 的 CPU 传感器是 cpuss-2（真机 thermal_zone27），
# TWRP 默认读 thermal_zone0，该平台 zone0 是 pa，读不到值
TW_CUSTOM_CPU_TEMP_PATH := "/sys/class/thermal/thermal_zone27/temp"

# 内核模块
# 显示、电池、USB、加密相关驱动在 vendor_boot 的 modules.load.recovery 里，第一阶段
# init 会自动加载。触控驱动不在其中，需要从 vendor_dlkm 单独加载：
# dtbo 中触控控制器为 novatek,NVT-ts-spi，对应 nt36532_touch.ko，另需 xiaomi_touch.ko。
TW_LOAD_VENDOR_MODULES := "xiaomi_touch.ko nt36532_touch.ko"
TW_LOAD_VENDOR_MODULES_EXCLUDE_GKI := true

# 功能
TW_INCLUDE_FASTBOOTD := true
TW_INCLUDE_REPACKTOOLS := true
TW_INCLUDE_RESETPROP := true
TW_INCLUDE_LIBRESETPROP := true
TW_INCLUDE_LPTOOLS := true
TW_INCLUDE_LPDUMP := true
TW_INCLUDE_7ZA := true
TW_INCLUDE_ZSTD := true
TW_INCLUDE_NTFS_3G := true
TW_USE_TOOLBOX := true
TW_EXCLUDE_APEX := true
TW_USE_SERIALNO_PROPERTY_FOR_DEVICE_ID := true
# 高通平台的虚拟触摸设备会抢占触摸输入，屏蔽它
TW_INPUT_BLACKLIST := "hbtp_vm"
# 只用设备树里的 recovery.fstab。vendor fstab 的 /data 带 checkpoint=fs，vold 会把它
# 挂成 checkpoint=disable，recovery 中的写入重启后会回滚。
TW_SKIP_ADDITIONAL_FSTAB := true
TW_BACKUP_EXCLUSIONS := /data/fonts,/data/adb/ap,/data/adb/ksu

# 调试
TWRP_INCLUDE_LOGCAT := true
TARGET_USES_LOGD := true
TARGET_RECOVERY_DEVICE_MODULES += debuggerd
RECOVERY_BINARY_SOURCE_FILES += $(TARGET_OUT_EXECUTABLES)/debuggerd

# 震动（可选，默认关闭）
# OF 树用源码编译的 AIDL vibrator HAL（vendor/qcom/opensource/vibrator）驱动
# qcom-hv-haptics。YARP 的 manifest 不包含该仓库，直接打开会导致 BOARD_RECOVERY_IMAGE_PREPARE
# 里的 cp 失败并中断构建。需要震动反馈时，在 local_manifest 里补上该仓库后取消注释。
#TW_SUPPORT_INPUT_AIDL_HAPTICS := true
#TARGET_RECOVERY_DEVICE_MODULES += vendor.qti.hardware.vibrator.service
#BOARD_RECOVERY_IMAGE_PREPARE += \
#    mkdir -p $(TARGET_RECOVERY_ROOT_OUT)/vendor/bin/hw \
#             $(TARGET_RECOVERY_ROOT_OUT)/vendor/lib64 \
#             $(TARGET_RECOVERY_ROOT_OUT)/vendor/etc/init \
#             $(TARGET_RECOVERY_ROOT_OUT)/vendor/etc/vintf/manifest && \
#    cp -f $(PRODUCT_OUT)/vendor/bin/hw/vendor.qti.hardware.vibrator.service $(TARGET_RECOVERY_ROOT_OUT)/vendor/bin/hw/ && \
#    cp -f $(PRODUCT_OUT)/vendor/lib64/*vibrator*.so $(TARGET_RECOVERY_ROOT_OUT)/vendor/lib64/ && \
#    cp -f $(PRODUCT_OUT)/vendor/etc/vintf/manifest/vendor.qti.hardware.vibrator.service.xml $(TARGET_RECOVERY_ROOT_OUT)/vendor/etc/vintf/manifest/ && \
#    cd $(TARGET_RECOVERY_ROOT_OUT) && find . | sed 's|^\./||' > ramdisk-files.txt
