find_package(Threads REQUIRED)

llama_add_compile_flags()

add_subdirectory("${PROJECT_SOURCE_DIR}/../frontend" "${CMAKE_BINARY_DIR}/frontend")
add_subdirectory(mtmd)
add_subdirectory(server)
