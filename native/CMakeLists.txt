cmake_minimum_required(VERSION 3.24)

project(nativeapi_shared LANGUAGES CXX C)

# Build the core static library from the submodule, then re-export the whole
# archive as the shared library the C# binding loads via P/Invoke.
add_subdirectory(${CMAKE_CURRENT_SOURCE_DIR}/../cxx_impl/src nativeapi_core)

add_library(nativeapi_shared SHARED shim.cpp)
target_link_libraries(nativeapi_shared PRIVATE
  $<LINK_LIBRARY:WHOLE_ARCHIVE,nativeapi>)
set_target_properties(nativeapi_shared PROPERTIES OUTPUT_NAME nativeapi)
