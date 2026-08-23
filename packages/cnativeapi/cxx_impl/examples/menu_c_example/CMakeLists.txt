cmake_minimum_required(VERSION 3.16)
project(menu_c_example)

set(CMAKE_C_STANDARD 11)

# Include the nativeapi headers
include_directories(${CMAKE_SOURCE_DIR}/../../include)

# Add the executable
add_executable(menu_c_example main.c)

# Link against the nativeapi library
target_link_libraries(menu_c_example nativeapi)

# Platform-specific settings
if(CMAKE_SYSTEM_NAME STREQUAL "iOS")
    # iOS uses UIKit, Foundation, CoreGraphics (already linked by nativeapi)
elseif(APPLE)
    find_library(COCOA_LIBRARY Cocoa)
    target_link_libraries(menu_c_example ${COCOA_LIBRARY})
elseif(WIN32)
    target_link_libraries(menu_c_example user32 kernel32)
elseif(CMAKE_SYSTEM_NAME STREQUAL "Linux")
    find_package(PkgConfig REQUIRED)
    pkg_check_modules(GTK3 REQUIRED gtk+-3.0)
    target_include_directories(menu_c_example PRIVATE ${GTK3_INCLUDE_DIRS})
    target_link_libraries(menu_c_example ${GTK3_LIBRARIES})
elseif(ANDROID)
    target_link_libraries(menu_c_example log android)
endif()
