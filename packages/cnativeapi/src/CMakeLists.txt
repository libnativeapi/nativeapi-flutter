# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.10)

project(cnativeapi VERSION 0.0.1 LANGUAGES CXX)

# Set C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Define base paths
set(LIBNATIVEAPI_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/libnativeapi")
set(LIBNATIVEAPI_SRC_DIR "${LIBNATIVEAPI_ROOT}/src")
set(LIBNATIVEAPI_INCLUDE_DIR "${LIBNATIVEAPI_ROOT}/include")

# Common source files
file(GLOB COMMON_SOURCES "${LIBNATIVEAPI_SRC_DIR}/*.cpp" "${LIBNATIVEAPI_SRC_DIR}/foundation/*.cpp")
list(FILTER COMMON_SOURCES EXCLUDE REGEX "${LIBNATIVEAPI_SRC_DIR}/platform/*")

# C API source files
file(GLOB CAPI_SOURCES
        "${LIBNATIVEAPI_SRC_DIR}/capi/*.cpp"
        "${LIBNATIVEAPI_SRC_DIR}/capi/*.c"
)

# Platform-specific source files
if(ANDROID)
    file(GLOB PLATFORM_SOURCES "${LIBNATIVEAPI_SRC_DIR}/platform/android/*.cpp")
elseif(CMAKE_SYSTEM_NAME STREQUAL "Linux")
    file(GLOB PLATFORM_SOURCES "${LIBNATIVEAPI_SRC_DIR}/platform/linux/*.cpp")
    # Find packages for Linux
    find_package(PkgConfig REQUIRED)
    pkg_check_modules(GTK REQUIRED IMPORTED_TARGET gtk+-3.0)
    pkg_check_modules(X11 REQUIRED IMPORTED_TARGET x11)
    pkg_check_modules(XI REQUIRED IMPORTED_TARGET xi)
    pkg_check_modules(AYATANA_APPINDICATOR REQUIRED IMPORTED_TARGET ayatana-appindicator3-0.1)
elseif (APPLE)
    file(GLOB PLATFORM_SOURCES "${LIBNATIVEAPI_SRC_DIR}/platform/macos/*.mm")
    # Find required frameworks for macOS
    find_library(COCOA_FRAMEWORK Cocoa)
    find_library(CARBON_FRAMEWORK Carbon)
    find_library(COREGRAPHICS_FRAMEWORK CoreGraphics)
    find_library(APPLICATIONSERVICES_FRAMEWORK ApplicationServices)
elseif (WIN32)
    file(GLOB PLATFORM_SOURCES "${LIBNATIVEAPI_SRC_DIR}/platform/windows/*.cpp")
else ()
    set(PLATFORM_SOURCES "")
endif ()

# Add library target
add_library(cnativeapi SHARED
        ${COMMON_SOURCES}
        ${PLATFORM_SOURCES}
        ${CAPI_SOURCES}
)

# Set library properties
set_target_properties(cnativeapi PROPERTIES
        PUBLIC_HEADER "${LIBNATIVEAPI_INCLUDE_DIR}/nativeapi.h"
)

# Set library include directories
target_include_directories(cnativeapi PUBLIC
        $<BUILD_INTERFACE:${LIBNATIVEAPI_INCLUDE_DIR}>
        $<INSTALL_INTERFACE:include>
)

if (CMAKE_SYSTEM_NAME STREQUAL "Linux")
    target_include_directories(cnativeapi PUBLIC ${GTK_INCLUDE_DIRS})
endif ()

# Link required frameworks and libraries
if(ANDROID)
    target_link_libraries(cnativeapi PUBLIC log android)
elseif (CMAKE_SYSTEM_NAME STREQUAL "Linux")
    target_link_libraries(cnativeapi PUBLIC
            PkgConfig::GTK
            PkgConfig::X11
            PkgConfig::XI
            PkgConfig::AYATANA_APPINDICATOR
            pthread
    )
elseif (WIN32)
    target_link_libraries(cnativeapi PUBLIC user32 shell32 dwmapi gdiplus crypt32)
endif ()

target_compile_definitions(cnativeapi PUBLIC DART_SHARED_LIB)
