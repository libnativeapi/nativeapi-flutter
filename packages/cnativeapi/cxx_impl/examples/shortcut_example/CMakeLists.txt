# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.10)

project(shortcut_example)

# Set C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Add executable
add_executable(shortcut_example main.cpp)

# Link with the native API library
target_link_libraries(shortcut_example nativeapi)

# Set include directories
target_include_directories(shortcut_example PRIVATE ../../include)

