#
# Copyright (C) 2026 The Android Open Source Project
#
# SPDX-License-Identifier: Apache-2.0
#
# 小米平板 6 Max 14（yudi）产品定义
#
# 构建：lunch twrp_yudi-eng && mka recoveryimage
#

DEVICE_PATH := device/xiaomi/yudi

# 设备配置
$(call inherit-product, $(DEVICE_PATH)/device.mk)

# 机型标识
# 这一段直接决定 recovery 里 build.prop 的值：
#   ro.product.device      <- PRODUCT_DEVICE
#   ro.product.name        <- PRODUCT_NAME
#   ro.product.model       <- PRODUCT_MODEL
#   ro.product.brand       <- PRODUCT_BRAND
# 注意：不要从同平台的 liuqin（小米平板 6 Pro）树复制这一段。留成 liuqin 会让
# ro.product.device 变成 liuqin，OTA 断言、脚本判断、备份命名、模块作用域判断都会错。
# 真机 getprop 实测：ro.product.device=yudi，ro.product.model=2307BRPDCC。
PRODUCT_DEVICE := yudi
PRODUCT_NAME := twrp_yudi
PRODUCT_BRAND := Xiaomi
PRODUCT_MODEL := 2307BRPDCC
PRODUCT_MANUFACTURER := Xiaomi
