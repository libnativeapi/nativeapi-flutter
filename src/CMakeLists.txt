# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.10)

project(nativeapi_library VERSION 0.0.1 LANGUAGES CXX)

# Add the libnativeapi source files
file(GLOB NATIVEAPI_SOURCES
  "${CMAKE_CURRENT_SOURCE_DIR}/libnativeapi/src/**/*.cpp"
  "${CMAKE_CURRENT_SOURCE_DIR}/**/*.cpp"
)

if(APPLE)
  file(GLOB NATIVEAPI_MM_SOURCES
    "${CMAKE_CURRENT_SOURCE_DIR}/libnativeapi/src/**/*.mm"
  )
  list(APPEND NATIVEAPI_SOURCES ${NATIVEAPI_MM_SOURCES})
endif()

add_library(nativeapi SHARED ${NATIVEAPI_SOURCES})

set_target_properties(nativeapi PROPERTIES
  PUBLIC_HEADER "${CMAKE_CURRENT_SOURCE_DIR}/libnativeapi/src/**/*.h"
  OUTPUT_NAME "nativeapi"
)

target_compile_definitions(nativeapi PUBLIC DART_SHARED_LIB)

if(ANDROID)
  # Support Android 15 16k page size
  target_link_options(nativeapi PRIVATE "-Wl,-z,max-page-size=16384")
endif()
