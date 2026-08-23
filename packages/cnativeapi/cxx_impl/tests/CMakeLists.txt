add_executable(url_opener_test url_opener_test.cpp)
target_link_libraries(url_opener_test PRIVATE nativeapi)
add_test(NAME url_opener_test COMMAND url_opener_test)

# Links the full library because EventEmitter now routes async delivery through
# the platform dispatcher. The test installs its own dispatcher (see
# FakeMainThread) so no run loop is required at runtime.
find_package(Threads REQUIRED)
add_executable(event_emitter_test event_emitter_test.cpp)
target_link_libraries(event_emitter_test PRIVATE nativeapi Threads::Threads)
add_test(NAME event_emitter_test COMMAND event_emitter_test)
set_tests_properties(event_emitter_test PROPERTIES TIMEOUT 120)

add_executable(id_allocator_test id_allocator_test.cpp)
target_link_libraries(id_allocator_test PRIVATE nativeapi Threads::Threads)
add_test(NAME id_allocator_test COMMAND id_allocator_test)

add_executable(handle_table_test handle_table_test.cpp)
target_link_libraries(handle_table_test PRIVATE nativeapi Threads::Threads)
add_test(NAME handle_table_test COMMAND handle_table_test)
set_tests_properties(handle_table_test PROPERTIES TIMEOUT 120)

add_executable(shortcut_accelerator_test shortcut_accelerator_test.cpp)
target_link_libraries(shortcut_accelerator_test PRIVATE nativeapi)
add_test(NAME shortcut_accelerator_test COMMAND shortcut_accelerator_test)

find_package(Threads REQUIRED)
add_executable(window_manager_hook_test window_manager_hook_test.cpp)
target_link_libraries(window_manager_hook_test PRIVATE nativeapi Threads::Threads)
add_test(NAME window_manager_hook_test COMMAND window_manager_hook_test)
set_tests_properties(window_manager_hook_test PROPERTIES TIMEOUT 120)
