# Built by cmake-js (`npm run build`), which supplies the Node-API headers and,
# on Windows, the import library through the CMAKE_JS_* variables.
cmake_minimum_required(VERSION 3.24)

project(nativeapi_js LANGUAGES CXX C)
if(APPLE)
  enable_language(OBJCXX)
endif()

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

# The published package vendors core into cxx_impl/; in this repository the
# binding builds against the core/ submodule directly.
if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/cxx_impl/src/CMakeLists.txt")
  set(NATIVEAPI_CORE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/cxx_impl")
else()
  set(NATIVEAPI_CORE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../../core")
endif()
add_subdirectory("${NATIVEAPI_CORE_DIR}/src" nativeapi_core)

file(GLOB GENERATED_SOURCES "src/generated/*.cc")
set(SOURCES
  src/addon.cc
  src/napi_support.cc
  src/event_loop_common.cc
  ${GENERATED_SOURCES}
)
if(APPLE)
  list(APPEND SOURCES src/event_loop_macos.mm)
elseif(WIN32)
  list(APPEND SOURCES src/event_loop_windows.cc)
else()
  list(APPEND SOURCES src/event_loop_linux.cc)
endif()

add_library(nativeapi_js SHARED ${SOURCES} ${CMAKE_JS_SRC})
set_target_properties(nativeapi_js PROPERTIES
  OUTPUT_NAME nativeapi
  PREFIX ""
  SUFFIX ".node"
)
target_include_directories(nativeapi_js PRIVATE
  ${CMAKE_JS_INC}
  "${NATIVEAPI_CORE_DIR}/src"
)
target_compile_definitions(nativeapi_js PRIVATE NAPI_VERSION=8)
target_link_libraries(nativeapi_js PRIVATE nativeapi ${CMAKE_JS_LIB})

if(MSVC AND CMAKE_JS_NODELIB_DEF AND CMAKE_JS_NODELIB_TARGET)
  execute_process(COMMAND ${CMAKE_AR} /def:${CMAKE_JS_NODELIB_DEF}
                  /out:${CMAKE_JS_NODELIB_TARGET} ${CMAKE_STATIC_LINKER_FLAGS})
endif()
