cmake_minimum_required(VERSION 3.15)
project(shortcut_c_example)

set(CMAKE_C_STANDARD 11)

add_executable(shortcut_c_example main.c)

target_include_directories(shortcut_c_example PRIVATE
    ${CMAKE_SOURCE_DIR}/include
    ${CMAKE_SOURCE_DIR}/src/capi
)

target_link_libraries(shortcut_c_example PRIVATE nativeapi)

