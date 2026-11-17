# Stage 8 脱敏实测摘要

来源：本机最终验收 QUAD_UNLOCK_4GPU_GEMM.csv、QUAD_PERSISTENCE_FINAL.md，非早期 BLOCKED 报告。仅摘录允许公开的统计字段；原始私有日志未上传。硬件基线见适用范围。

4/4 Unlock；四卡固件／FLR／handoff ret=0／unlocked 均成功；ss0=0x88888888、ss1=0x8。正常重启后逐卡复核成功。BF16：74.45→122.40、82.92→134.08、83.89→134.34、80.84→126.04 TFLOPS。完整三精度数据见 [gemm.csv](gemm.csv)。单卡串行测量，不能理解为四卡同时满载成绩。

历史报告属于用户提交的本机实验记录；本次发布整理未重新运行硬件测试。冷启动未测，四卡满载未测。
