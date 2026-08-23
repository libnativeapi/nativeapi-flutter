cmake_minimum_required(VERSION 3.10)

# Set C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Create executable for ID allocator example
add_executable(id_allocator_example main.cpp)

# Link against the nativeapi library
target_link_libraries(id_allocator_example nativeapi)
