#
# Copyright (C) 2026 The Android Open Source Project
#
# SPDX-License-Identifier: Apache-2.0
#
# 小米平板 6 Max 14（yudi）设备级产品配置
#

DEVICE_PATH := device/xiaomi/yudi

# 基础配置
$(call inherit-product, $(SRC_TARGET_DIR)/product/base.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit_only.mk)

# 虚拟 A/B：官方 OTA 的动态分区元数据 snapshot_enabled = true
$(call inherit-product, $(SRC_TARGET_DIR)/product/virtual_ab_ota.mk)

# 模拟存储
$(call inherit-product, $(SRC_TARGET_DIR)/product/emulated_storage.mk)

# TWRP 通用配置
$(call inherit-product, vendor/twrp/config/common.mk)

# API 级别
# 原厂 vendor/build.prop 的 ro.board.first_api_level = 31。保持 31 可避免把 vendor
# 库的 VNDK 要求抬到构建分支的 36，进而导致 vendor 服务加载失败。
PRODUCT_SHIPPING_API_LEVEL := 31

# recovery 不运行 ART。关闭 UFFD GC，避免构建系统为取 sysprop 去内核中提取版本号
# —— Android 14 起 sysprop.mk 默认依赖内核版本，会让不带内核的 recovery 构建失败。
PRODUCT_ENABLE_UFFD_GC := false

# 本树只构建 recovery，不生成 OTA，关闭 OTA 的内核 VINTF 要求
PRODUCT_OTA_ENFORCE_VINTF_KERNEL_REQUIREMENTS := false

# 动态分区（真机 ro.boot.dynamic_partitions=true）
PRODUCT_USE_DYNAMIC_PARTITIONS := true

# FUSE passthrough
PRODUCT_PROPERTY_OVERRIDES += persist.sys.fuse.passthrough.enable=true

# fastbootd
PRODUCT_PACKAGES += \
    android.hardware.fastboot@1.1-impl-mock \
    fastbootd

# 测试签名证书：recovery 的额外 key，配合 BOARD_AVB_RECOVERY_KEY_PATH
PRODUCT_EXTRA_RECOVERY_KEYS += \
    $(DEVICE_PATH)/security/releasekey

# Soong 命名空间
PRODUCT_SOONG_NAMESPACES += \
    $(DEVICE_PATH)

# 震动 HAL 从源码构建（需在 manifest 中补充 vendor/qcom/opensource/vibrator，
# 否则本行静默跳过，BoardConfig 中对应功能默认关闭）
$(call inherit-product-if-exists, vendor/qcom/opensource/vibrator/vibrator-vendor-product.mk)
