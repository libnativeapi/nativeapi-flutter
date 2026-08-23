cmake_minimum_required(VERSION 3.10)

project(launch_at_login_c_example)

set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)

# Add executable
add_executable(launch_at_login_c_example main.c)

# Link with the native API library
target_link_libraries(launch_at_login_c_example nativeapi)

# Set include directories
target_include_directories(launch_at_login_c_example PRIVATE ../../include)
