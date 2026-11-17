# 回滚

一次启动：在 GRUB 编辑页删除 `gpu_unlock.targets=...`，启动进入系统。

持久关闭：备份后从 `/etc/default/grub` 删除该参数，执行 `sudo update-grub`，检查生成配置，再人工重启。要卸载包，先用 `dpkg-query -W 'gpu-unlock*'` 确认包名，再用 `sudo apt remove gpu-unlock-dkms gpu-unlock-firmware`；包的移除钩子会更新 initramfs。检查选用内核的 initramfs 和 GRUB，确保不再自动加载和指定目标。

已经生效的硬件状态不保证在本次运行中即时撤销。以重启后逐卡日志和同设置 GEMM 验证为准。挂起／掉电等状态不能代替持久配置回滚。Stage 8 的恢复方案做过 dry-run 与故障注入，未实际执行整机回滚。
