# The Flutter tooling requires that developers have a version of Visual Studio
# installed that includes CMake 3.14 or later. You should not increase this
# version, as doing so will cause the plugin to fail to compile for some
# customers of the plugin.
cmake_minimum_required(VERSION 3.14)

# Project-level configuration.
set(PROJECT_NAME "cnativeapi")
project(${PROJECT_NAME} LANGUAGES CXX)

# Flutter has no public flag for arbitrary CMake definitions. Allow the example
# launcher to select core's optional backend through process-local variables.
foreach(_option NATIVEAPI_ENABLE_WINUI3 NATIVEAPI_WINAPPSDK_DIR
                NATIVEAPI_CPPWINRT_EXE NATIVEAPI_WEBVIEW2_DIR)
  if(DEFINED ENV{${_option}})
    set(${_option} "$ENV{${_option}}" CACHE STRING "nativeapi build option" FORCE)
  endif()
endforeach()

# Invoke the build for native code shared with the other target platforms.
# This can be changed to accommodate different builds.
add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/../src" "${CMAKE_CURRENT_BINARY_DIR}/shared")

set(_winui3_libraries "")
if(NATIVEAPI_ENABLE_WINUI3)
  if(CMAKE_GENERATOR_PLATFORM MATCHES "ARM64")
    set(_winui3_arch arm64)
  elseif(CMAKE_SIZEOF_VOID_P EQUAL 8)
    set(_winui3_arch x64)
  else()
    set(_winui3_arch x86)
  endif()
  list(APPEND _winui3_libraries
    "${NATIVEAPI_WINAPPSDK_DIR}/runtimes/win-${_winui3_arch}/native/Microsoft.WindowsAppRuntime.Bootstrap.dll")
endif()

# List of absolute paths to libraries that should be bundled with the plugin.
# This list could contain prebuilt libraries, or libraries created by an
# external build triggered from this build file.
set(cnativeapi_bundled_libraries
  # Defined in ../src/CMakeLists.txt.
  # This can be changed to accommodate different builds.
  $<TARGET_FILE:cnativeapi>
  ${_winui3_libraries}
  PARENT_SCOPE
)
