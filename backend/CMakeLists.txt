cmake_minimum_required(VERSION 3.19...3.28)

project("llama-server" C CXX)

# Inherited llama.cpp library version, used by shared library properties.
set(LLAMA_VERSION_MAJOR 0)
set(LLAMA_VERSION_MINOR 5)
set(LLAMA_VERSION_PATCH 0)
set(LLAMA_VERSION_BASE "${LLAMA_VERSION_MAJOR}.${LLAMA_VERSION_MINOR}.${LLAMA_VERSION_PATCH}")
set(LLAMA_VERSION "${LLAMA_VERSION_BASE}")

include(CheckIncludeFileCXX)

if (NOT CMAKE_SYSTEM_PROCESSOR MATCHES "^(x86_64|AMD64|amd64)$")
    message(FATAL_ERROR "This project is reduced to x86-64 APU targets")
endif()

if (NOT XCODE AND NOT MSVC AND NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Release CACHE STRING "Build type" FORCE)
    set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS Debug Release MinSizeRel RelWithDebInfo)
endif()

message(STATUS "CMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}")

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin")
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin")

option(LLAMA_APU_OPTIMIZED "Enable performance-oriented build defaults for x86-64 APUs" ON)

# This project produces a single, target-specific server. Static internal
# libraries let IPO optimize across the ggml/llama/server boundaries and avoid
# dynamic-library indirection in the hot path. This does not request a fully
# static system binary.
if (LLAMA_APU_OPTIMIZED OR MINGW)
    set(BUILD_SHARED_LIBS_DEFAULT OFF)
else()
    set(BUILD_SHARED_LIBS_DEFAULT ON)
endif()

option(BUILD_SHARED_LIBS "Build shared libraries" ${BUILD_SHARED_LIBS_DEFAULT})
option(LLAMA_USE_SYSTEM_GGML "Use the system libggml" OFF)
option(LLAMA_ALL_WARNINGS "Enable compiler warnings" ON)
option(LLAMA_FATAL_WARNINGS "Treat compiler warnings as errors" OFF)
option(LLAMA_OPENSSL "Enable HTTPS through OpenSSL" ON)
option(LLAMA_SUBPROCESS "Enable subprocess support required by router mode and video input" ON)
option(LLAMA_LLGUIDANCE "Enable LLGuidance structured output" OFF)
option(LLAMA_BUILD_UI "Build the embedded Web UI" ON)

if (LLAMA_APU_OPTIMIZED)
    # Keep every setting overridable from the command line. Setting these
    # before adding ggml changes only the first-configure defaults.
    if (NOT DEFINED GGML_VULKAN)
        set(GGML_VULKAN ON CACHE BOOL "ggml: use Vulkan")
    endif()
    if (NOT DEFINED GGML_NATIVE)
        set(GGML_NATIVE ON CACHE BOOL "ggml: optimize the build for the current system")
    endif()
    if (NOT DEFINED GGML_LTO)
        set(GGML_LTO ON CACHE BOOL "ggml: enable link time optimization")
    endif()
endif()

# ggml enables IPO in its own directory when GGML_LTO is active. Enable it at
# the project root as well so the final server and the static common libraries
# participate in the same optimization pass.
if (GGML_LTO)
    include(CheckIPOSupported)
    check_ipo_supported(RESULT LLAMA_APU_IPO_SUPPORTED OUTPUT LLAMA_APU_IPO_ERROR)
    if (LLAMA_APU_IPO_SUPPORTED)
        set(CMAKE_INTERPROCEDURAL_OPTIMIZATION ON)
    else()
        message(WARNING "IPO is not supported: ${LLAMA_APU_IPO_ERROR}")
    endif()
endif()

if (LLAMA_APU_OPTIMIZED AND GGML_NATIVE AND
        (CMAKE_C_COMPILER_ID MATCHES "GNU|Clang" OR CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang"))
    add_compile_options(
        "$<$<COMPILE_LANGUAGE:C>:-march=native>"
        "$<$<COMPILE_LANGUAGE:CXX>:-march=native>"
    )
endif()

message(STATUS "APU optimized defaults: ${LLAMA_APU_OPTIMIZED}")
message(STATUS "Vulkan backend: ${GGML_VULKAN}")
message(STATUS "Native CPU code: ${GGML_NATIVE}")
message(STATUS "Link-time optimization: ${GGML_LTO}")
message(STATUS "Shared internal libraries: ${BUILD_SHARED_LIBS}")

if (WIN32)
    add_compile_definitions(_CRT_SECURE_NO_WARNINGS)
endif()

if (MSVC)
    add_compile_options(
        "$<$<COMPILE_LANGUAGE:C>:/utf-8>"
        "$<$<COMPILE_LANGUAGE:CXX>:/utf-8>"
        "$<$<COMPILE_LANGUAGE:C>:/bigobj>"
        "$<$<COMPILE_LANGUAGE:CXX>:/bigobj>"
    )
endif()

include("${CMAKE_CURRENT_SOURCE_DIR}/cmake/build-info.cmake")
include("${CMAKE_CURRENT_SOURCE_DIR}/cmake/common.cmake")

set(LLAMA_BUILD_NUMBER ${BUILD_NUMBER})
set(LLAMA_BUILD_COMMIT ${BUILD_COMMIT})
set(LLAMA_INSTALL_VERSION "0.0.${LLAMA_BUILD_NUMBER}")

set(GGML_ALL_WARNINGS ${LLAMA_ALL_WARNINGS})
set(GGML_FATAL_WARNINGS ${LLAMA_FATAL_WARNINGS})

if (NOT DEFINED GGML_LLAMAFILE)
    set(GGML_LLAMAFILE_DEFAULT ON)
endif()

if (LLAMA_USE_SYSTEM_GGML)
    find_package(ggml REQUIRED)
    add_library(ggml ALIAS ggml::ggml)
else()
    set(GGML_BUILD_NUMBER ${LLAMA_BUILD_NUMBER})
    set(GGML_BUILD_COMMIT ${LLAMA_BUILD_COMMIT})
    add_subdirectory(ggml)
endif()

add_subdirectory(src)

# The vendored libraries are exposed as CMake targets (vendor::hash,
# vendor::nlohmann, ...). common and the server are always built here.
set(LLAMA_BUILD_COMMON ON)
add_subdirectory(vendor)
add_subdirectory(common)
add_subdirectory(tools)
