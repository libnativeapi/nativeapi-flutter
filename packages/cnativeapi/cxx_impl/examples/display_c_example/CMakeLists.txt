cmake_minimum_required(VERSION 3.10)

project(display_c_example)

set(CMAKE_C_STANDARD 99)

add_executable(display_c_example main.c)

target_link_libraries(display_c_example nativeapi)

target_include_directories(display_c_example PRIVATE
  ${CMAKE_CURRENT_SOURCE_DIR}/../../include
)
