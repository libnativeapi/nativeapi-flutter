# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.10)

project(cnativeapi VERSION 0.0.1 LANGUAGES CXX)

# Set C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Core sources: the published package carries a copy in cxx_impl/ (vendored by
# the release workflow); inside the nativeapi-workspace repository the plugin
# builds the checkout's core/ directly. Apps reach this directory through
# Flutter's .plugin_symlinks, so resolve the real location before walking up.
get_filename_component(CNATIVEAPI_SRC_REAL "${CMAKE_CURRENT_SOURCE_DIR}" REALPATH)
if(EXISTS "${CNATIVEAPI_SRC_REAL}/../cxx_impl/src/CMakeLists.txt")
    get_filename_component(LIBNATIVEAPI_ROOT "${CNATIVEAPI_SRC_REAL}/../cxx_impl" ABSOLUTE)
else()
    get_filename_component(LIBNATIVEAPI_ROOT "${CNATIVEAPI_SRC_REAL}/../../../../core" ABSOLUTE)
endif()
if(NOT EXISTS "${LIBNATIVEAPI_ROOT}/src/CMakeLists.txt")
    message(FATAL_ERROR "nativeapi core sources not found at ${LIBNATIVEAPI_ROOT}; "
                        "run `git submodule update --init core` in the repository")
endif()
set(LIBNATIVEAPI_SRC_DIR "${LIBNATIVEAPI_ROOT}/src")
set(LIBNATIVEAPI_INCLUDE_DIR "${LIBNATIVEAPI_ROOT}/include")

# Use core's Windows build rules so optional backends and system libraries stay
# in sync. Compile the C ABI into the DLL to retain every exported entry point.
if(WIN32)
    add_subdirectory("${LIBNATIVEAPI_SRC_DIR}" "${CMAKE_CURRENT_BINARY_DIR}/nativeapi")
    file(GLOB CAPI_SOURCES "${LIBNATIVEAPI_SRC_DIR}/capi/*.cpp" "${LIBNATIVEAPI_SRC_DIR}/capi/*.c")
    add_library(cnativeapi SHARED ${CAPI_SOURCES})
    if(MSVC)
        target_compile_options(nativeapi PRIVATE /utf-8)
        target_compile_options(cnativeapi PRIVATE /utf-8)
    endif()
    target_link_libraries(cnativeapi PRIVATE nativeapi ole32 uuid)
    target_compile_definitions(cnativeapi PUBLIC DART_SHARED_LIB)
    return()
endif()

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
elseif (APPLE)
    file(GLOB PLATFORM_SOURCES "${LIBNATIVEAPI_SRC_DIR}/platform/macos/*.mm")
    # Find required frameworks for macOS
    find_library(COCOA_FRAMEWORK Cocoa)
    find_library(CARBON_FRAMEWORK Carbon)
    find_library(COREGRAPHICS_FRAMEWORK CoreGraphics)
    find_library(APPLICATIONSERVICES_FRAMEWORK ApplicationServices)
    find_library(SERVICEMANAGEMENT_FRAMEWORK ServiceManagement)
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
    # Android 15 runs on devices with 16 KB memory pages; a shared library whose
    # segments are aligned to 4 KB does not load there.
    target_link_options(cnativeapi PRIVATE "-Wl,-z,max-page-size=16384")
elseif (CMAKE_SYSTEM_NAME STREQUAL "Linux")
    target_link_libraries(cnativeapi PUBLIC
            PkgConfig::GTK
            PkgConfig::X11
            PkgConfig::XI
            pthread
    )
elseif (APPLE)
    target_link_libraries(cnativeapi PUBLIC
            "${COCOA_FRAMEWORK}"
            "${CARBON_FRAMEWORK}"
            "${COREGRAPHICS_FRAMEWORK}"
            "${APPLICATIONSERVICES_FRAMEWORK}"
            "${SERVICEMANAGEMENT_FRAMEWORK}"
    )
elseif (WIN32)
    target_link_libraries(cnativeapi PUBLIC user32 shell32 dwmapi gdiplus crypt32)
endif ()

target_compile_definitions(cnativeapi PUBLIC DART_SHARED_LIB)
