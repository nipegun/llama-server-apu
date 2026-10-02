cmake_minimum_required(VERSION 3.19)

# Only build this fork's UI: upstream assets lack its locales and API routes.
set(cDistributionDirectory "${UI_BINARY_DIR}/dist")
set(cWorkDirectory "${UI_BINARY_DIR}/ui-src")
set(cStampPath "${UI_BINARY_DIR}/.apu-ui-source-hash")
set(cTemporaryDirectory "${LLAMA_SOURCE_DIR}/../_/temp")

function(fBuildUi)
  find_program(vNpmExecutable NAMES npm npm.cmd REQUIRED)
  file(GLOB_RECURSE lSourceFiles LIST_DIRECTORIES FALSE
    "${UI_SOURCE_DIR}/src/*" "${UI_SOURCE_DIR}/static/*" "${UI_SOURCE_DIR}/scripts/*")
  file(GLOB lConfigurationFiles LIST_DIRECTORIES FALSE "${UI_SOURCE_DIR}/*")
  list(APPEND lSourceFiles ${lConfigurationFiles})
  list(SORT lSourceFiles)
  set(vFingerprint "${LLAMA_BUILD_NUMBER}")
  foreach(vSourceFile IN LISTS lSourceFiles)
    file(SHA256 "${vSourceFile}" vFileHash)
    string(APPEND vFingerprint "${vSourceFile}:${vFileHash}\n")
  endforeach()
  string(SHA256 cSourceHash "${vFingerprint}")
  if(EXISTS "${cStampPath}" AND EXISTS "${cDistributionDirectory}/index.html")
    file(READ "${cStampPath}" vPreviousHash)
    if(vPreviousHash STREQUAL cSourceHash)
      return()
    endif()
  endif()
  file(MAKE_DIRECTORY "${cWorkDirectory}" "${cTemporaryDirectory}/npm-cache")
  file(GLOB lStagedEntries RELATIVE "${cWorkDirectory}" "${cWorkDirectory}/*" "${cWorkDirectory}/.[!.]*")
  list(REMOVE_ITEM lStagedEntries "node_modules")
  foreach(vEntry IN LISTS lStagedEntries)
    file(REMOVE_RECURSE "${cWorkDirectory}/${vEntry}")
  endforeach()
  file(COPY "${UI_SOURCE_DIR}/" DESTINATION "${cWorkDirectory}"
    PATTERN "node_modules" EXCLUDE PATTERN "dist" EXCLUDE PATTERN ".svelte-kit" EXCLUDE)
  execute_process(
    COMMAND "${CMAKE_COMMAND}" -E env "npm_config_cache=${cTemporaryDirectory}/npm-cache"
      "TMPDIR=${cTemporaryDirectory}" "${vNpmExecutable}" ci --no-audit --no-fund
    WORKING_DIRECTORY "${cWorkDirectory}" RESULT_VARIABLE vInstallStatus)
  if(NOT vInstallStatus EQUAL 0)
    message(FATAL_ERROR "UI dependency installation failed; no upstream fallback is permitted")
  endif()
  file(REMOVE_RECURSE "${cDistributionDirectory}")
  execute_process(
    COMMAND "${CMAKE_COMMAND}" -E env "LLAMA_UI_OUT_DIR=${cDistributionDirectory}"
      "LLAMA_BUILD_NUMBER=${LLAMA_BUILD_NUMBER}" "npm_config_cache=${cTemporaryDirectory}/npm-cache"
      "TMPDIR=${cTemporaryDirectory}" "${vNpmExecutable}" run build
    WORKING_DIRECTORY "${cWorkDirectory}" RESULT_VARIABLE vBuildStatus)
  if(NOT vBuildStatus EQUAL 0 OR NOT EXISTS "${cDistributionDirectory}/index.html")
    message(FATAL_ERROR "UI build failed; stale or upstream assets will not be embedded")
  endif()
  file(WRITE "${cStampPath}" "${cSourceHash}")
endfunction()

if(BUILD_UI)
  fBuildUi()
else()
  set(cDistributionDirectory "")
endif()

if(LLAMA_UI_GZIP AND BUILD_UI)
  find_program(vGzipExecutable gzip REQUIRED)
  file(REMOVE_RECURSE "${cDistributionDirectory}/_gzip")
  file(GLOB_RECURSE lAssets LIST_DIRECTORIES FALSE RELATIVE "${cDistributionDirectory}" "${cDistributionDirectory}/*")
  foreach(vAsset IN LISTS lAssets)
    get_filename_component(vParent "${cDistributionDirectory}/_gzip/${vAsset}" DIRECTORY)
    file(MAKE_DIRECTORY "${vParent}")
    execute_process(COMMAND "${vGzipExecutable}" -c "${cDistributionDirectory}/${vAsset}"
      OUTPUT_FILE "${cDistributionDirectory}/_gzip/${vAsset}" RESULT_VARIABLE vGzipStatus)
    if(NOT vGzipStatus EQUAL 0)
      message(FATAL_ERROR "UI compression failed for ${vAsset}")
    endif()
  endforeach()
endif()

set(aEmbedArguments "${UI_BINARY_DIR}/ui.cpp" "${UI_BINARY_DIR}/ui.h")
if(BUILD_UI)
  list(APPEND aEmbedArguments "${cDistributionDirectory}")
endif()
execute_process(COMMAND "${LLAMA_UI_EMBED}" ${aEmbedArguments} RESULT_VARIABLE vEmbedStatus)
if(NOT vEmbedStatus EQUAL 0)
  message(FATAL_ERROR "UI asset embedding failed")
endif()
