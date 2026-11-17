// SPDX-License-Identifier: MIT
// Minimal cuBLAS GEMM benchmark for FP16 / BF16 / TF32 with FP32 accumulation.
// Usage: ./gemm_bench --device N --dtype fp16|bf16|tf32 [--m 8192 --n 8192 --k 8192 --iters 100]
#include <cublas_v2.h>
#include <cuda_runtime.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define CK(x)                                                                 \
	do {                                                                   \
		cudaError_t e_ = (x);                                          \
		if (e_ != cudaSuccess) {                                       \
			fprintf(stderr, "CUDA %s:%d: %s\n", __FILE__, __LINE__, \
				cudaGetErrorString(e_));                       \
			exit(2);                                               \
		}                                                              \
	} while (0)

#define CB(x)                                                                  \
	do {                                                                   \
		cublasStatus_t s_ = (x);                                       \
		if (s_ != CUBLAS_STATUS_SUCCESS) {                             \
			fprintf(stderr, "cuBLAS %s:%d: %d\n", __FILE__, __LINE__, \
				(int)s_);                                      \
			exit(3);                                               \
		}                                                              \
	} while (0)

int main(int argc, char **argv)
{
	int dev = 0, m = 8192, n = 8192, k = 8192, iters = 100;
	const char *dtype = "bf16";
	for (int i = 1; i < argc; i++) {
		if (!strcmp(argv[i], "--device") && i + 1 < argc)
			dev = atoi(argv[++i]);
		else if (!strcmp(argv[i], "--dtype") && i + 1 < argc)
			dtype = argv[++i];
		else if (!strcmp(argv[i], "--m") && i + 1 < argc)
			m = atoi(argv[++i]);
		else if (!strcmp(argv[i], "--n") && i + 1 < argc)
			n = atoi(argv[++i]);
		else if (!strcmp(argv[i], "--k") && i + 1 < argc)
			k = atoi(argv[++i]);
		else if (!strcmp(argv[i], "--iters") && i + 1 < argc)
			iters = atoi(argv[++i]);
		else {
			fprintf(stderr, "bad arg %s\n", argv[i]);
			return 2;
		}
	}
	if (m < 256 || n < 256 || k < 256 || iters < 1) {
		fprintf(stderr, "bad sizes\n");
		return 2;
	}

	cudaDataType_t abt, ct;
	cublasComputeType_t compute;
	size_t esize;
	if (!strcmp(dtype, "fp16")) {
		abt = ct = CUDA_R_16F;
		compute = CUBLAS_COMPUTE_32F;
		esize = 2;
	} else if (!strcmp(dtype, "bf16")) {
		abt = ct = CUDA_R_16BF;
		compute = CUBLAS_COMPUTE_32F;
		esize = 2;
	} else if (!strcmp(dtype, "tf32")) {
		abt = ct = CUDA_R_32F;
		compute = CUBLAS_COMPUTE_32F_FAST_TF32;
		esize = 4;
	} else {
		fprintf(stderr, "dtype must be fp16|bf16|tf32\n");
		return 2;
	}

	CK(cudaSetDevice(dev));
	cudaDeviceProp prop;
	CK(cudaGetDeviceProperties(&prop, dev));
	int clock_khz = 0;
	CK(cudaDeviceGetAttribute(&clock_khz, cudaDevAttrClockRate, dev));
	printf("DEVICE %d %s cc=%d.%d sm=%d MHz mem=%d MiB\n", dev, prop.name,
	       prop.major, prop.minor, clock_khz / 1000,
	       (int)(prop.totalGlobalMem >> 20));

	cublasHandle_t h;
	CB(cublasCreate(&h));
	CB(cublasSetMathMode(h, CUBLAS_TENSOR_OP_MATH));

	void *A = NULL, *B = NULL, *C = NULL;
	size_t sa = (size_t)m * k * esize, sb = (size_t)k * n * esize,
	       sc = (size_t)m * n * esize;
	CK(cudaMalloc(&A, sa));
	CK(cudaMalloc(&B, sb));
	CK(cudaMalloc(&C, sc));
	CK(cudaMemset(A, 0x3c, sa));
	CK(cudaMemset(B, 0x3c, sb));
	CK(cudaMemset(C, 0, sc));

	float alpha = 1.0f, beta = 0.0f;
	// Row-major A (m x k), B (k x n), C (m x n): compute C^T = B^T A^T.
	// cuBLAS is column-major, so pass N,M,K with B as the first operand.
	auto gemm = [&]() {
		return cublasGemmEx(h, CUBLAS_OP_N, CUBLAS_OP_N, n, m, k, &alpha,
				    B, abt, n, A, abt, k, &beta, C, ct, n,
				    compute, CUBLAS_GEMM_DEFAULT_TENSOR_OP);
	};

	for (int i = 0; i < 10; i++)
		CB(gemm());
	CK(cudaDeviceSynchronize());

	cudaEvent_t e0, e1;
	CK(cudaEventCreate(&e0));
	CK(cudaEventCreate(&e1));
	CK(cudaEventRecord(e0));
	for (int i = 0; i < iters; i++)
		CB(gemm());
	CK(cudaEventRecord(e1));
	CK(cudaEventSynchronize(e1));
	float ms = 0;
	CK(cudaEventElapsedTime(&ms, e0, e1));
	double tflops = 2.0 * (double)m * n * k * iters / (ms / 1000.0) / 1e12;
	printf("RESULT device=%d dtype=%s m=%d n=%d k=%d iters=%d tflops=%.2f ms_total=%.2f ms_per_gemm=%.3f\n",
	       dev, dtype, m, n, k, iters, tflops, ms, ms / iters);

	CK(cudaEventDestroy(e0));
	CK(cudaEventDestroy(e1));
	CB(cublasDestroy(h));
	CK(cudaFree(A));
	CK(cudaFree(B));
	CK(cudaFree(C));
	return 0;
}
