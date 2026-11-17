# 启动链

固定版上游核心位于 `upstream/unlock/kernel/gpu_unlock/`：recipes.c 识别设备，firmware_610／gfw_eval／unlock_610 处理固件与解锁，main.c 负责目标与驱动前启动流程。firmware/ 提供输入下载及提取源码，packaging/boot/ 与 debian/ 提供开机加载和打包。

流程：显式 targets → initramfs 模块 → 固件事务／速度选择器 → FLR → host handoff → NVIDIA 驱动绑定。Stage 8 四卡记录 ss0=0x88888888、ss1=0x8，四次 handoff ret=0 和四次 unlocked。只看模块是否加载不足以证明每卡成功。

核心及构建脚本从固定 commit 下载，不以本项目名义重写或扩大其硬件兼容性结论。
