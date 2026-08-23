cmake_minimum_required(VERSION 3.10)

project(application_example VERSION 0.0.1 LANGUAGES CXX)

# Set C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Add example program
add_executable(application_example
        "main.cpp"
)

# Link main library
target_link_libraries(application_example PRIVATE nativeapi)

# Set example program properties
set_target_properties(application_example PROPERTIES
        OUTPUT_NAME "application_example"
)

# Set example program compile options (macOS only)
if(APPLE)
    set_source_files_properties("main.cpp"
            PROPERTIES
            COMPILE_FLAGS "-x objective-c++"
    )
endif()
