# 安装与启动

先读 [适用范围](compatibility.md)。需要 git、编译环境、当前内核 headers、DKMS、Ubuntu 打包依赖及网络；上游 `make install` 会请求 sudo 并安装依赖和包。固件提取版本 610.43.03 不等于运行驱动版本，本次运行驱动是 615.71.09。请先阅读上游 firmware/NOTICE.md，不要公开生成的固件包。

1. 按首页获取固定源码并执行真实上游 `make install`。
2. 用 `lspci -Dnn` 选择 NVIDIA display/3D 功能完整地址；不要复制别人的 BDF。
3. 备份 `/etc/default/grub`，编辑 `GRUB_CMDLINE_LINUX_DEFAULT`，保留已有参数，追加一个参数。例如单卡 `gpu_unlock.targets=0000:21:00.0`，多卡 `gpu_unlock.targets=0000:21:00.0,0000:22:00.0`（仅语法示例）。不默认使用 all。
4. `sudo update-grub`，检查生成的启动配置和 initramfs；在有本机恢复手段时人工重启。
5. 查看内核日志，每个目标都应出现成功的固件／FLR／handoff／unlocked 记录；以逐卡日志和 GEMM 前后对比共同判断。

Ubuntu initramfs-tools 包含 gpu_unlock 模块和固件，在 NVIDIA 绑定前运行。不要启动后对已绑定显卡强行重跑 unlock，也不要为了尝试而修改 VBIOS。独立使用本项目不要求 patched P2P 驱动；这里只记录该驱动上的实测组合。

首页命令测试 GPU index 0；多卡依次替换 --device。每张卡分别跑 fp16、bf16、tf32，使用相同 8192³／100 iterations 设置与基线对比。CUDA Toolkit 提供 nvcc/cuBLAS，需自行合法安装，仓库不捆绑。
