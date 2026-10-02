cmake_minimum_required(VERSION 3.19...3.28)

project("llama-server-apu" LANGUAGES C CXX)

add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/../backend" "${CMAKE_CURRENT_BINARY_DIR}/backend")
