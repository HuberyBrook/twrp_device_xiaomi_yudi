# 小米平板 6 Max 14（yudi）TWRP 设备树 — YARP

小米平板 6 Max 14（代号 **yudi**，型号 2307BRPDCC，骁龙 8+ Gen 1 / taro）的 TWRP 设备树，按 [TWRP-Test](https://github.com/orgs/TWRP-Test/repositories)（YARP）规范组织，目标分支 `twrp-16.0`（android16.0.0_r1）。

> **状态**：结构已按 YARP 规范搭好，板级参数全部来自真机实测与已验证的 OrangeFox 树，但**本树本身尚未经过一次完整构建与上机验证**。请以 CI 产物实测为准，功能状态见下表。

## 与来源的关系

| 来源 | 用途 |
| --- | --- |
| 真机 `yudi`（adb + root） | 分区表、分区容量、fstab、屏幕、背光、温控、触摸模块、机型属性 |
| 真机 `boot_a`（magiskboot unpack） | 头部版本、页大小、ramdisk 格式、`--os_version 12.0.0 --os_patch_level 2025-09` |
| [OneFeiFan/device_xiaomi_yudi](https://github.com/OneFeiFan/device_xiaomi_yudi)（GPL-3，OrangeFox） | 板级结论（加密、显示旋转、KeyMint 补丁级别）、ramdisk 内的厂商服务与固件 |
| [xccxxcys/device_xiaomi_liuqin-TWRP-OF](https://github.com/xccxxcys/device_xiaomi_liuqin-TWRP-OF) | 同平台（taro）结构对照 |
| [TWRP-Test/twrp_device_xiaomi_sm8850](https://github.com/TWRP-Test/twrp_device_xiaomi_sm8850) | YARP 目录结构与 CI 规范 |

本树是 OrangeFox 树的**重新组织与裁剪**，不是复制：去掉了橙狐专用的 `vendorsetup.sh`、`OF_*` 构建变量、`twres` 主题资源与源码补丁，改用 YARP 的 `device.mk` / `TARGET_RECOVERY_FSTAB` / CI 工作流结构。

## 设备标识（重要）

`build.prop` 的机型字段由 `twrp_yudi.mk` 决定，本树固定为：

```
PRODUCT_DEVICE       := yudi
PRODUCT_NAME         := twrp_yudi
PRODUCT_MODEL        := 2307BRPDCC
PRODUCT_BRAND        := Xiaomi
TARGET_OTA_ASSERT_DEVICE := yudi
```

同平台的 liuqin（小米平板 6 Pro）设备树产出的是 `ro.product.device=liuqin`。本树**不沿用**该值——否则 OTA 断言、脚本机型判断、备份命名、模块作用域都会错。

## 关键板级参数

| 项 | 值 | 依据 |
| --- | --- | --- |
| 平台 / 架构 | taro / `armv8-2a-dotprod` | 真机 `ro.board.platform` |
| 内核 | 0 字节占位，`BOARD_EXCLUDE_KERNEL_FROM_RECOVERY_IMAGE` | 原厂 recovery 头部 `kernel_size = 0`，bootloader 复用 boot 分区内核 |
| 镜像头 | v4 / 4096 / lz4 / `12.0.0` / `2025-09` | 真机 boot 头部实测 |
| 分区 | 有独立 `recovery`（100 MB）与 `vendor_boot`，无 `init_boot`、无 `system_dlkm` | 真机 `/dev/block/by-name` |
| super | 实测 11811160064；构建用分区组上限 10 GiB + 4 MiB | 真机 blockdev / OTA 元数据 |
| 文件系统 | 逻辑分区 erofs，userdata f2fs，metadata ext4 | 真机 fstab |
| 屏幕 | 1800x2880，`TW_ROTATION 270`，`TW_X_OFFSET 90`，`TW_W_OFFSET -180` | 真机 wm size + OF 四角实测 |
| 背光 | `max_brightness = 4095` | 真机 sysfs |
| CPU 温度 | `thermal_zone27`（cpuss-2） | 真机 thermal_zone 映射 |
| 触摸模块 | `xiaomi_touch.ko`、`nt36532_touch.ko` | 真机 `/vendor/lib/modules` + dtbo 节点 |
| 加密 | FBE v2 + metadata 加密，fscrypt policy 2，`TW_USE_DMCTL` | 真机 fstab `fileencryption` / `metadata_encryption` |

## 构建

```bash
repo init -u https://github.com/TWRP-Test/platform_manifest_twrp_aosp.git -b twrp-16.0 --depth=1
repo sync -j$(nproc)

git clone https://github.com/<owner>/twrp_device_xiaomi_yudi.git -b twrp-16.0 device/xiaomi/yudi

export ALLOW_MISSING_DEPENDENCIES=true
. build/envsetup.sh
lunch twrp_yudi-eng
mka recoveryimage
```

产物：`out/target/product/yudi/recovery.img`，刷入 `recovery` 分区：

```bash
fastboot flash recovery out/target/product/yudi/recovery.img
```

也可以直接用仓库里的 [`.github/workflows/build.yml`](.github/workflows/build.yml)：Actions → TWRP 16 Builder → Run workflow，参数默认值已按本树填好。

## 功能状态

本树尚未构建验证，以下仅为**预期**，需要在真机上逐项确认：

| 功能 | 状态 |
| --- | --- |
| 启动、显示、触摸 | 待验证 |
| 解密 data | 待验证 |
| ADB / MTP / sideload | 待验证 |
| fastbootd | 待验证 |
| 备份恢复、双清、Format Data | 待验证 |
| USB OTG | 待验证，依赖 `twrp.flags` 的 `/usb_otg` 条目 |
| 震动 | 默认关闭，见下 |

OrangeFox 树在相同板级配置下已验证上述大部分功能，可作对照：[功能状态](https://github.com/OneFeiFan/device_xiaomi_yudi#功能状态)。

## 注意事项

1. **安全补丁级别必须与 ROM 一致**。厂商 `libqtikeymint` 会比对 `ro.build.version.security_patch` 与 `ro.vendor.build.security_patch`，写小了会返回 `-62 KEY_REQUIRES_UPGRADE`，升级又必然失败（`-8`），表现为**解密彻底不可用**。ROM 更新后需同步修改 `BoardConfig.mk` 中的三个值并重新构建。
2. **震动默认关闭**。OF 树用源码编译的 AIDL vibrator HAL 驱动 `qcom-hv-haptics`，而 YARP 的 manifest 不含 `vendor/qcom/opensource/vibrator`。需要时先往 `local_manifest` 补该仓库，再打开 `BoardConfig.mk` 中被注释的块和 `init.recovery.qcom.rc` 里的三行。
3. **不要用 HTTPS 克隆**（特定网络环境下 `github.com:443` 不可达时）：本机验证过 `22` 端口可用，请使用 SSH。
4. **双清不解除锁屏**：普通双清保留 user 0 的锁屏凭据，需要清锁屏请用 Format Data。
5. `prebuilt/kernel` 是**故意留空的 0 字节文件**，不要往里放内核——放进去反而会改变镜像结构。

## 许可证

GPL-3.0。ramdisk 内的厂商二进制来自设备 ROM，来源说明见 OrangeFox 树的 `proprietary-files.txt`。
