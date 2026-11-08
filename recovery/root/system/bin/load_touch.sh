#!/system/bin/sh
# 触摸模块加载
#
# 优先加载当前 ROM 的 vendor_dlkm 里的模块——它的 vermagic 与正在运行的内核一致。
# 只有在 vendor_dlkm 不可用（例如切到一个尚未装系统的槽位，分区大小为 0）时，
# 才退回 ramdisk 里的副本。
#
# 不使用 TWRP 的 TW_LOAD_VENDOR_MODULES：那条路径要求在构建期跑 depmod 生成
# modules.dep，而 YARP 的 twrp-16.0 分支没有把宿主 depmod 编出来，会直接中断构建。
# 这里用 insmod 直接加载，不需要 modules.dep。

load_one() {
    name="$1"
    # 已经加载过就跳过
    grep -q "^${name} " /proc/modules 2>/dev/null && return 0

    if [ -f "/vendor/lib/modules/${name}.ko" ]; then
        /system/bin/insmod "/vendor/lib/modules/${name}.ko" 2>/dev/null && return 0
    fi

    if [ -f "/lib/modules/${name}.ko" ]; then
        /system/bin/insmod "/lib/modules/${name}.ko" 2>/dev/null && return 0
    fi

    log -t recovery "load_touch: ${name}.ko 加载失败"
    return 1
}

load_one xiaomi_touch
load_one nt36532_touch
