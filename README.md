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
| 触摸模块 | `xiaomi_touch.ko`、`nt36532_touch.ko`，由 init 阶段 `load_touch.sh` 直接 insmod | 真机 `/vendor/lib/modules` + dtbo 节点 |
| 加密 | FBE v2 + metadata 加密，fscrypt policy 2，`TW_USE_DMCTL` | 真机 fstab `fileencryption` / `metadata_encryption` |
| 系统版本 | Android 17 / SDK 37 / `OS4.0.6.0.XMHCNXM`，vendor release 12 | 真机 `getprop` |

## 解密相关（最容易被忽略的地方）

recovery 必须**声称和系统一样的版本与补丁级别**，否则厂商 KeyMint 会判定 metadata key 需要升级：返回 `-62 KEY_REQUIRES_UPGRADE`，升级动作又必然失败（`-8`），结果就是**解密完全不可用**。

当前固件下的正确值（`BoardConfig.mk` 已按此填写）：

```
ro.build.version.release          = 17          -> PLATFORM_VERSION
ro.build.version.security_patch   = 2026-10-01  -> PLATFORM_SECURITY_PATCH / BOOT_SECURITY_PATCH
ro.vendor.build.security_patch    = 2026-02-01  -> VENDOR_SECURITY_PATCH
```

ROM 更新后**必须重新核对这三个值并重新构建**：

```bash
adb shell getprop ro.build.version.release
adb shell getprop ro.build.version.security_patch
adb shell getprop ro.vendor.build.security_patch
```

`ro.build.version.release` 有个坑：AOSP 里它取自 **`PLATFORM_VERSION_LAST_STABLE`**，而不是 `PLATFORM_VERSION`（后者只进 `release_or_codename` 和指纹）。所以 `PLATFORM_VERSION_LAST_STABLE` 必须也是 17。代价是 CTS 的版本清单（来自 android16.0.0_r1，只有 14/15/16/99.87.36）校验会失败，构建前需补一行：

```bash
echo 17 >> cts/tests/tests/os/assets/platform_releases.txt
```

CI 工作流里已有对应的 "Patch CTS platform releases" 步骤，本地构建请手动执行。

已知差异：本树基于 `android16.0.0_r1`，因此 recovery 的 `ro.build.version.sdk` 为 36，而设备是 37。KeyMint 的升级判定用 `release` 与 `security_patch`（均已对齐为 17 / 2026-10-01），若将来出现无法解释的 `-62`，SDK 差异是第一个要排查的点。


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

1. **安全补丁级别必须与 ROM 一致**。详见上面[解密相关](#解密相关最容易被忽略的地方)一节。ROM 更新后需同步修改 `BoardConfig.mk` 中的三个值并重新构建。
2. **bootloader 状态需要确认**。真机当前 `ro.boot.verifiedbootstate=green`、`ro.boot.flash.locked=1`，即**引导锁为锁定状态**。锁定状态下 `fastboot flash recovery` 会被拒绝，需先解锁（会清空数据）。若你是通过重打包签名的方式维持锁定，刷入本镜像前请先确认签名方式，否则可能无法启动。
3. **不要启用 `TW_LOAD_VENDOR_MODULES`**。该变量会让构建系统在打包 ramdisk 时调用宿主 `depmod` 生成 `modules.dep`，而 YARP 的 `twrp-16.0` 分支没有把 `depmod` 编出来，会直接中断构建（`ramdisk_files-timestamp` 失败）。本树改用 `recovery/root/system/bin/load_touch.sh` 在 init 阶段 `insmod`，优先取当前 ROM 的 `/vendor/lib/modules`，不需要 `modules.dep`，也不会有内核版本不匹配的风险。
4. **震动默认关闭**。OF 树用源码编译的 AIDL vibrator HAL 驱动 `qcom-hv-haptics`，而 YARP 的 manifest 不含 `vendor/qcom/opensource/vibrator`。需要时先往 `local_manifest` 补该仓库，再打开 `BoardConfig.mk` 中被注释的块和 `init.recovery.qcom.rc` 里的三行。
5. **不要用 HTTPS 克隆**（特定网络环境下 `github.com:443` 不可达时）：本机验证过 `22` 端口可用，请使用 SSH。
6. **双清不解除锁屏**：普通双清保留 user 0 的锁屏凭据，需要清锁屏请用 Format Data。
7. `prebuilt/kernel` 是**故意留空的 0 字节文件**，不要往里放内核——放进去反而会改变镜像结构。

## 许可证

GPL-3.0。ramdisk 内的厂商二进制来自设备 ROM，来源说明见 OrangeFox 树的 `proprietary-files.txt`。
