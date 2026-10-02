cmake_minimum_required(VERSION 3.14...3.28) # for add_link_options and implicit target directories.

project("ggml" C CXX ASM)

### GGML Version
set(GGML_VERSION_MAJOR 0)
set(GGML_VERSION_MINOR 25)
set(GGML_VERSION_PATCH 3)
set(GGML_VERSION_BASE "${GGML_VERSION_MAJOR}.${GGML_VERSION_MINOR}.${GGML_VERSION_PATCH}")

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake/")

set(GGML_VERSION "${GGML_VERSION_BASE}")

if(NOT GGML_BUILD_COMMIT)
    set(GGML_BUILD_COMMIT "unknown")
endif()

include(CheckIncludeFileCXX)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

if (NOT XCODE AND NOT MSVC AND NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Release CACHE STRING "Build type" FORCE)
    set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS "Debug" "Release" "MinSizeRel" "RelWithDebInfo")
endif()

if (CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
    set(GGML_STANDALONE ON)

    set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)

    # configure project version
    # TODO
else()
    set(GGML_STANDALONE OFF)

    if (NOT CMAKE_RUNTIME_OUTPUT_DIRECTORY)
        set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
    endif()
endif()

if (EMSCRIPTEN)
    set(BUILD_SHARED_LIBS_DEFAULT OFF)

    option(GGML_WASM_SINGLE_FILE "ggml: embed WASM inside the generated ggml.js" ON)
else()
    if (MINGW)
        set(BUILD_SHARED_LIBS_DEFAULT OFF)
    else()
        set(BUILD_SHARED_LIBS_DEFAULT ON)
    endif()
endif()

# remove the lib prefix on win32 mingw
if (WIN32)
    set(CMAKE_STATIC_LIBRARY_PREFIX "")
    set(CMAKE_SHARED_LIBRARY_PREFIX "")
    set(CMAKE_SHARED_MODULE_PREFIX  "")
endif()

option(BUILD_SHARED_LIBS           "ggml: build shared libraries" ${BUILD_SHARED_LIBS_DEFAULT})
option(GGML_BACKEND_DL             "ggml: build backends as dynamic libraries (requires BUILD_SHARED_LIBS)" OFF)
set(GGML_BACKEND_DIR "" CACHE PATH "ggml: directory to load dynamic backends from (requires GGML_BACKEND_DL")

#
# option list
#

# TODO: mark all options as advanced when not GGML_STANDALONE

set(GGML_BLAS_DEFAULT OFF)
set(GGML_BLAS_VENDOR_DEFAULT "Generic")

if (CMAKE_CROSSCOMPILING OR DEFINED ENV{SOURCE_DATE_EPOCH})
    message(STATUS "Setting GGML_NATIVE_DEFAULT to OFF")
    set(GGML_NATIVE_DEFAULT OFF)
else()
    set(GGML_NATIVE_DEFAULT ON)
endif()

# defaults
if (NOT GGML_LLAMAFILE_DEFAULT)
    set(GGML_LLAMAFILE_DEFAULT OFF)
endif()

# general
option(GGML_STATIC "ggml: static link libraries"                     OFF)
option(GGML_NATIVE "ggml: optimize the build for the current system" ${GGML_NATIVE_DEFAULT})
option(GGML_LTO    "ggml: enable link time optimization"             OFF)
option(GGML_CCACHE "ggml: use ccache if available"                   ON)

# debug
option(GGML_ALL_WARNINGS           "ggml: enable all compiler warnings"                   ON)
option(GGML_ALL_WARNINGS_3RD_PARTY "ggml: enable all compiler warnings in 3rd party libs" OFF)
option(GGML_GPROF                  "ggml: enable gprof"                                   OFF)

# build
option(GGML_FATAL_WARNINGS    "ggml: enable -Werror flag"    OFF)

# sanitizers
option(GGML_SANITIZE_THREAD    "ggml: enable thread sanitizer"    OFF)
option(GGML_SANITIZE_ADDRESS   "ggml: enable address sanitizer"   OFF)
option(GGML_SANITIZE_UNDEFINED "ggml: enable undefined sanitizer" OFF)

# instruction set specific
if (GGML_NATIVE OR NOT GGML_NATIVE_DEFAULT)
    set(INS_ENB OFF)
else()
    set(INS_ENB ON)
endif()

message(DEBUG "GGML_NATIVE         : ${GGML_NATIVE}")
message(DEBUG "GGML_NATIVE_DEFAULT : ${GGML_NATIVE_DEFAULT}")
message(DEBUG "INS_ENB             : ${INS_ENB}")

option(GGML_CPU_HBM          "ggml: use memkind for CPU HBM" OFF)
option(GGML_CPU_REPACK       "ggml: use runtime weight conversion of Q4_0 to Q4_X_X" ON)
option(GGML_SSE42            "ggml: enable SSE 4.2"          ${INS_ENB})
option(GGML_AVX              "ggml: enable AVX"              ${INS_ENB})
option(GGML_AVX_VNNI         "ggml: enable AVX-VNNI"         OFF)
option(GGML_AVX2             "ggml: enable AVX2"             ${INS_ENB})
option(GGML_BMI2             "ggml: enable BMI2"             ${INS_ENB})
option(GGML_AVX512           "ggml: enable AVX512F"          OFF)
option(GGML_AVX512_VBMI      "ggml: enable AVX512-VBMI"      OFF)
option(GGML_AVX512_VNNI      "ggml: enable AVX512-VNNI"      OFF)
option(GGML_AVX512_BF16      "ggml: enable AVX512-BF16"      OFF)
if (NOT MSVC)
    # in MSVC F16C and FMA is implied with AVX2/AVX512
    option(GGML_FMA          "ggml: enable FMA"              ${INS_ENB})
    option(GGML_F16C         "ggml: enable F16C"             ${INS_ENB})
    # MSVC does not seem to support AMX
    option(GGML_AMX_TILE     "ggml: enable AMX-TILE"         OFF)
    option(GGML_AMX_INT8     "ggml: enable AMX-INT8"         OFF)
    option(GGML_AMX_BF16     "ggml: enable AMX-BF16"         OFF)
endif()
# ggml core
set(GGML_SCHED_MAX_COPIES  "4" CACHE STRING "ggml: max input copies for pipeline parallelism")
option(GGML_CPU                             "ggml: enable CPU backend"                        ON)
option(GGML_SCHED_NO_REALLOC                "ggml: disallow reallocations in ggml-alloc (for debugging)" OFF)

# 3rd party libs / backends
option(GGML_BLAS                            "ggml: use BLAS"                                  ${GGML_BLAS_DEFAULT})
set(GGML_BLAS_VENDOR ${GGML_BLAS_VENDOR_DEFAULT} CACHE STRING
                                            "ggml: BLAS library vendor")
option(GGML_LLAMAFILE                       "ggml: use LLAMAFILE"                             ${GGML_LLAMAFILE_DEFAULT})

option(GGML_CUDA_FORCE_MMQ                  "ggml: use mmq kernels instead of cuBLAS"         OFF)
option(GGML_CUDA_FORCE_CUBLAS               "ggml: always use cuBLAS instead of mmq kernels"  OFF)
option(GGML_CUDA_NO_PEER_COPY               "ggml: do not use peer to peer copies"            OFF)
option(GGML_CUDA_FA                         "ggml: compile ggml FlashAttention CUDA kernels"  ON)

option(GGML_HIP                             "ggml: use HIP"                                   OFF)
option(GGML_HIP_GRAPHS                      "ggml: use HIP graph"                              ON)
option(GGML_HIP_RCCL                        "ggml: use ROCm Collective Comm. Library"         OFF)
option(GGML_HIP_NO_VMM                      "ggml: do not try to use HIP VMM"                 ON)
option(GGML_HIP_MMQ_MFMA                    "ggml: enable MFMA MMA for CDNA in MMQ"           ON)
option(GGML_HIP_EXPORT_METRICS              "ggml: enable kernel perf metrics output"         OFF)
option(GGML_VULKAN                          "ggml: use Vulkan"                                OFF)
option(GGML_VULKAN_DEBUG                    "ggml: enable Vulkan debug output"                OFF)
option(GGML_VULKAN_MEMORY_DEBUG             "ggml: enable Vulkan memory debug output"         OFF)
option(GGML_VULKAN_SHADER_DEBUG_INFO        "ggml: enable Vulkan shader debug info"           OFF)
option(GGML_VULKAN_VALIDATE                 "ggml: enable Vulkan validation"                  OFF)
option(GGML_OPENMP                          "ggml: use OpenMP"                                ON)

# toolchain for vulkan-shaders-gen
set   (GGML_VULKAN_SHADERS_GEN_TOOLCHAIN "" CACHE FILEPATH "ggml: toolchain file for vulkan-shaders-gen")

#
# dependencies
#

set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED true)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED true)

set(THREADS_PREFER_PTHREAD_FLAG ON)

find_package(Threads REQUIRED)

#
# build the library
#

add_subdirectory(src)

set(GGML_INSTALL_VERSION ${GGML_VERSION})

message(STATUS "ggml version: ${GGML_INSTALL_VERSION}")
message(STATUS "ggml commit:  ${GGML_BUILD_COMMIT}")

if (MSVC)
    set(MSVC_WARNING_FLAGS
        /wd4005  # Macro redefinition
        /wd4244  # Conversion from one type to another type, possible loss of data
        /wd4267  # Conversion from 'size_t' to a smaller type, possible loss of data
        /wd4305  # Conversion from 'type1' to 'type2', possible loss of data
        /wd4566  # Conversion from 'char' to 'wchar_t', possible loss of data
        /wd4996  # Disable POSIX deprecation warnings
        /wd4702  # Unreachable code warnings
    )
    set(MSVC_COMPILE_OPTIONS
        "$<$<COMPILE_LANGUAGE:C>:/utf-8>"
        "$<$<COMPILE_LANGUAGE:CXX>:/utf-8>"
    )
    function(configure_msvc_target target_name)
        if(TARGET ${target_name})
            target_compile_options(${target_name} PRIVATE ${MSVC_WARNING_FLAGS})
            target_compile_options(${target_name} PRIVATE ${MSVC_COMPILE_OPTIONS})
        endif()
    endfunction()

    configure_msvc_target(ggml-base)
    configure_msvc_target(ggml)
    configure_msvc_target(ggml-cpu)
    configure_msvc_target(ggml-cpu-x64)
    configure_msvc_target(ggml-cpu-sse42)
    configure_msvc_target(ggml-cpu-sandybridge)
    # __FMA__ and __F16C__ are not defined in MSVC, however they are implied with AVX2/AVX512
    # skipping            ggml-cpu-ivybridge
    # skipping            ggml-cpu-piledriver
    configure_msvc_target(ggml-cpu-haswell)
    configure_msvc_target(ggml-cpu-skylakex)
    configure_msvc_target(ggml-cpu-cannonlake)
    configure_msvc_target(ggml-cpu-cascadelake)
    configure_msvc_target(ggml-cpu-icelake)
    # MSVC 2022 doesn't support BF16 intrinsics without `/arch:AVX10.1` ?!
    # https://learn.microsoft.com/en-us/cpp/intrinsics/x64-amd64-intrinsics-list?view=msvc-170
    # https://learn.microsoft.com/en-us/cpp/build/reference/arch-x64?view=msvc-170
    # skipping            ggml-cpu-cooperlake
    # skipping            ggml-cpu-zen4
    configure_msvc_target(ggml-cpu-alderlake)
    # MSVC doesn't support AMX
    # skipping            ggml-cpu-sapphirerapids

endif()
