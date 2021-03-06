# Automatically-generated headers for cublas
#
# DO NOT EDIT THIS FILE DIRECTLY.


# Automatically generated using Clang.jl

const CUBLAS_VER_MAJOR = 10
const CUBLAS_VER_MINOR = 2
const CUBLAS_VER_PATCH = 2
const CUBLAS_VER_BUILD = 89
const CUBLAS_VERSION = CUBLAS_VER_MAJOR * 1000 + CUBLAS_VER_MINOR * 100 + CUBLAS_VER_PATCH

@cenum cublasStatus_t::UInt32 begin
    CUBLAS_STATUS_SUCCESS = 0
    CUBLAS_STATUS_NOT_INITIALIZED = 1
    CUBLAS_STATUS_ALLOC_FAILED = 3
    CUBLAS_STATUS_INVALID_VALUE = 7
    CUBLAS_STATUS_ARCH_MISMATCH = 8
    CUBLAS_STATUS_MAPPING_ERROR = 11
    CUBLAS_STATUS_EXECUTION_FAILED = 13
    CUBLAS_STATUS_INTERNAL_ERROR = 14
    CUBLAS_STATUS_NOT_SUPPORTED = 15
    CUBLAS_STATUS_LICENSE_ERROR = 16
end

@cenum cublasFillMode_t::UInt32 begin
    CUBLAS_FILL_MODE_LOWER = 0
    CUBLAS_FILL_MODE_UPPER = 1
    CUBLAS_FILL_MODE_FULL = 2
end

@cenum cublasDiagType_t::UInt32 begin
    CUBLAS_DIAG_NON_UNIT = 0
    CUBLAS_DIAG_UNIT = 1
end

@cenum cublasSideMode_t::UInt32 begin
    CUBLAS_SIDE_LEFT = 0
    CUBLAS_SIDE_RIGHT = 1
end

@cenum cublasOperation_t::UInt32 begin
    CUBLAS_OP_N = 0
    CUBLAS_OP_T = 1
    CUBLAS_OP_C = 2
    CUBLAS_OP_HERMITAN = 2
    CUBLAS_OP_CONJG = 3
end

@cenum cublasPointerMode_t::UInt32 begin
    CUBLAS_POINTER_MODE_HOST = 0
    CUBLAS_POINTER_MODE_DEVICE = 1
end

@cenum cublasAtomicsMode_t::UInt32 begin
    CUBLAS_ATOMICS_NOT_ALLOWED = 0
    CUBLAS_ATOMICS_ALLOWED = 1
end

@cenum cublasGemmAlgo_t::Int32 begin
    CUBLAS_GEMM_DFALT = -1
    CUBLAS_GEMM_DEFAULT = -1
    CUBLAS_GEMM_ALGO0 = 0
    CUBLAS_GEMM_ALGO1 = 1
    CUBLAS_GEMM_ALGO2 = 2
    CUBLAS_GEMM_ALGO3 = 3
    CUBLAS_GEMM_ALGO4 = 4
    CUBLAS_GEMM_ALGO5 = 5
    CUBLAS_GEMM_ALGO6 = 6
    CUBLAS_GEMM_ALGO7 = 7
    CUBLAS_GEMM_ALGO8 = 8
    CUBLAS_GEMM_ALGO9 = 9
    CUBLAS_GEMM_ALGO10 = 10
    CUBLAS_GEMM_ALGO11 = 11
    CUBLAS_GEMM_ALGO12 = 12
    CUBLAS_GEMM_ALGO13 = 13
    CUBLAS_GEMM_ALGO14 = 14
    CUBLAS_GEMM_ALGO15 = 15
    CUBLAS_GEMM_ALGO16 = 16
    CUBLAS_GEMM_ALGO17 = 17
    CUBLAS_GEMM_ALGO18 = 18
    CUBLAS_GEMM_ALGO19 = 19
    CUBLAS_GEMM_ALGO20 = 20
    CUBLAS_GEMM_ALGO21 = 21
    CUBLAS_GEMM_ALGO22 = 22
    CUBLAS_GEMM_ALGO23 = 23
    CUBLAS_GEMM_DEFAULT_TENSOR_OP = 99
    CUBLAS_GEMM_DFALT_TENSOR_OP = 99
    CUBLAS_GEMM_ALGO0_TENSOR_OP = 100
    CUBLAS_GEMM_ALGO1_TENSOR_OP = 101
    CUBLAS_GEMM_ALGO2_TENSOR_OP = 102
    CUBLAS_GEMM_ALGO3_TENSOR_OP = 103
    CUBLAS_GEMM_ALGO4_TENSOR_OP = 104
    CUBLAS_GEMM_ALGO5_TENSOR_OP = 105
    CUBLAS_GEMM_ALGO6_TENSOR_OP = 106
    CUBLAS_GEMM_ALGO7_TENSOR_OP = 107
    CUBLAS_GEMM_ALGO8_TENSOR_OP = 108
    CUBLAS_GEMM_ALGO9_TENSOR_OP = 109
    CUBLAS_GEMM_ALGO10_TENSOR_OP = 110
    CUBLAS_GEMM_ALGO11_TENSOR_OP = 111
    CUBLAS_GEMM_ALGO12_TENSOR_OP = 112
    CUBLAS_GEMM_ALGO13_TENSOR_OP = 113
    CUBLAS_GEMM_ALGO14_TENSOR_OP = 114
    CUBLAS_GEMM_ALGO15_TENSOR_OP = 115
end

@cenum cublasMath_t::UInt32 begin
    CUBLAS_DEFAULT_MATH = 0
    CUBLAS_TENSOR_OP_MATH = 1
end

const cublasDataType_t = cudaDataType
const cublasContext = Cvoid
const cublasHandle_t = Ptr{cublasContext}
const cublasLogCallback = Ptr{Cvoid}
const cublasXtContext = Cvoid
const cublasXtHandle_t = Ptr{cublasXtContext}

@cenum cublasXtPinnedMemMode_t::UInt32 begin
    CUBLASXT_PINNING_DISABLED = 0
    CUBLASXT_PINNING_ENABLED = 1
end

@cenum cublasXtOpType_t::UInt32 begin
    CUBLASXT_FLOAT = 0
    CUBLASXT_DOUBLE = 1
    CUBLASXT_COMPLEX = 2
    CUBLASXT_DOUBLECOMPLEX = 3
end

@cenum cublasXtBlasOp_t::UInt32 begin
    CUBLASXT_GEMM = 0
    CUBLASXT_SYRK = 1
    CUBLASXT_HERK = 2
    CUBLASXT_SYMM = 3
    CUBLASXT_HEMM = 4
    CUBLASXT_TRSM = 5
    CUBLASXT_SYR2K = 6
    CUBLASXT_HER2K = 7
    CUBLASXT_SPMM = 8
    CUBLASXT_SYRKX = 9
    CUBLASXT_HERKX = 10
    CUBLASXT_TRMM = 11
    CUBLASXT_ROUTINE_MAX = 12
end

