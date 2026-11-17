# GeForce Linux Tensor Unlock

Ubuntu 单卡／多卡 Tensor Core Unlock 复现资料：GPU 探测、固件加载、FLR、driver handoff、开机解锁和 GEMM 验证。核心实现来自 [Zagitta/gpu-unlock](THIRD_PARTY.md)，本仓库固定实测版本，不提供通用安装器。

**唯一严格验收基线**：Ubuntu 24.04.5 · kernel 6.8.0-149 · patched NVIDIA 615.71.09 · 4×RTX 3090。结果 **4/4 Unlock，warm reboot PASS**。冷启动、四卡同时满载未测。其他平台未验收。

### 安装

```bash
bash scripts/detect-gpus.sh
bash scripts/fetch-upstream.sh unlock
(cd upstream/unlock && make install)
```

接着按 [启动配置](docs/install.md) 把**自己选定的完整 PCI 地址**写入 `gpu_unlock.targets=`，更新 GRUB 后人工重启；单卡填一个，多卡逗号分隔。安装模块本身不会自动选择目标。

### 验证

```bash
sudo journalctl -k -b -o cat | grep gpu_unlock
mkdir -p build
nvcc -O2 -o build/gemm_bench src/gemm_bench.cu -lcublas
./build/gemm_bench --device 0 --dtype bf16 --iters 100
```

多卡逐卡串行执行；保留同设置的解锁前基线。GEMM 是吞吐量测试，不是数值正确性或四卡压力验收。

[安装与单／多卡](docs/install.md) · [机制](docs/architecture.md) · [回滚](docs/rollback.md) · [实测](reports/stage8.md) · [适用范围](docs/compatibility.md) · [许可证](THIRD_PARTY.md)

English: pinned Linux Tensor Core unlock reproduction for one or more GPUs. Only the four-RTX-3090 baseline above was accepted here.
