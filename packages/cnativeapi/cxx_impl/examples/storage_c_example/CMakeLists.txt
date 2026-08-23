cmake_minimum_required(VERSION 3.10)

project(storage_c_example)

set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)

# Add executable
add_executable(storage_c_example main.c)

# Link nativeapi library
target_link_libraries(storage_c_example PRIVATE nativeapi)

# Platform-specific settings
if(ANDROID)
    # Android platform doesn't need OpenSSL (secure_storage is stub implementation)
elseif(CMAKE_SYSTEM_NAME STREQUAL "iOS")
    target_link_libraries(storage_c_example PRIVATE "-framework Security")
elseif(CMAKE_SYSTEM_NAME STREQUAL "Linux")
    find_package(PkgConfig REQUIRED)
    pkg_check_modules(OPENSSL REQUIRED IMPORTED_TARGET openssl)
    target_link_libraries(storage_c_example PRIVATE PkgConfig::OPENSSL pthread)
elseif(APPLE)
    target_link_libraries(storage_c_example PRIVATE "-framework Cocoa" "-framework Security")
elseif(CMAKE_SYSTEM_NAME STREQUAL "OHOS")
    # OHOS platform doesn't need OpenSSL (secure_storage is stub implementation)
elseif(WIN32)
    target_link_libraries(storage_c_example PRIVATE user32 shell32 dwmapi gdiplus crypt32)
elseif(UNIX)
    find_package(PkgConfig REQUIRED)
    pkg_check_modules(OPENSSL REQUIRED IMPORTED_TARGET openssl)
    target_link_libraries(storage_c_example PRIVATE PkgConfig::OPENSSL pthread)
endif()

