cmake_minimum_required(VERSION 3.10)

project(launch_at_login_example)

# Set C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Add executable
add_executable(launch_at_login_example main.cpp)

# Link with the native API library
target_link_libraries(launch_at_login_example nativeapi)

# Set include directories
target_include_directories(launch_at_login_example PRIVATE ../../include)
