# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.10)

project(keyboard_example)

# Set C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Add executable
add_executable(keyboard_example main.cpp)

# Link with the native API library
target_link_libraries(keyboard_example nativeapi)

# Set include directories to find the C API header
target_include_directories(keyboard_example PRIVATE ../../src)
