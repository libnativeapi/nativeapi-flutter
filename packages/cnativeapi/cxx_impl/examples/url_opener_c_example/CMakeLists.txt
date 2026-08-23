cmake_minimum_required(VERSION 3.10)

project(url_opener_c_example)

set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)

add_executable(url_opener_c_example main.c)

target_link_libraries(url_opener_c_example nativeapi)

target_include_directories(url_opener_c_example PRIVATE ../../include)
