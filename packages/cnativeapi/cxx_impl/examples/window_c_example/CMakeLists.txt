cmake_minimum_required(VERSION 3.10)

project(window_c_example VERSION 0.0.1 LANGUAGES CXX)

# Set C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Add example program
add_executable(window_c_example
  "main.c"
)

# Link main library
target_link_libraries(window_c_example PRIVATE nativeapi)

# Set example program properties
set_target_properties(window_c_example PROPERTIES
  OUTPUT_NAME "window_c_example"
)

# Set example program compile options (macOS only)
if(APPLE)
    set_source_files_properties("main.cpp"
    PROPERTIES
    COMPILE_FLAGS "-x objective-c++"
  )
endif()
