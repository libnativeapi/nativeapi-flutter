# Builds the shared library the Python binding loads with ctypes: the whole
# core static archive plus the event loop shim for Application.run_async().
#
# Built by scikit-build-core when the wheel is built (`pip install .`), which
# installs the library into the `nativeapi` package; or by hand for a source
# checkout (`cmake -S . -B build && cmake --build build`), where
# nativeapi/_library.py finds it in build/.
cmake_minimum_required(VERSION 3.24)

project(nativeapi_python LANGUAGES CXX C)
if(APPLE)
  enable_language(OBJCXX)
endif()

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

# The published sdist vendors core into cxx_impl/; in this repository the
# binding builds against the core/ submodule directly.
if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/cxx_impl/src/CMakeLists.txt")
  set(NATIVEAPI_CORE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/cxx_impl")
else()
  set(NATIVEAPI_CORE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../../core")
endif()
add_subdirectory("${NATIVEAPI_CORE_DIR}/src" nativeapi_core)

set(SOURCES src/event_loop_common.cc)
if(APPLE)
  list(APPEND SOURCES src/event_loop_macos.mm)
elseif(WIN32)
  list(APPEND SOURCES src/event_loop_windows.cc)
else()
  list(APPEND SOURCES src/event_loop_linux.cc)
endif()

add_library(nativeapi_python SHARED ${SOURCES})
target_include_directories(nativeapi_python PRIVATE "${NATIVEAPI_CORE_DIR}/src")
# Re-export every C ABI symbol of the archive, not just the ones the shim uses.
target_link_libraries(nativeapi_python PRIVATE
  $<LINK_LIBRARY:WHOLE_ARCHIVE,nativeapi>)
if(WIN32)
  target_link_libraries(nativeapi_python PRIVATE ole32 uuid)
endif()
set_target_properties(nativeapi_python PROPERTIES
  OUTPUT_NAME nativeapi
  LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}"
  RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}"
)

if(SKBUILD)
  install(TARGETS nativeapi_python
    LIBRARY DESTINATION nativeapi
    RUNTIME DESTINATION nativeapi
  )
endif()
