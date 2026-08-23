#pragma once

#include <stdbool.h>

#ifdef __cplusplus
#include <map>
#include <string>
#include <vector>
#endif

#if _WIN32
#define FFI_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FFI_PLUGIN_EXPORT
#endif

#ifdef __cplusplus
extern "C" {
#endif

/**
 * String utilities for C API interoperability
 */

/**
 * An owning list of strings.
 *
 * Free with native_string_list_free(); it releases every item and the array.
 */
typedef struct {
  char** items;
  long count;
} native_string_list_t;

/**
 * An owning list of string key/value pairs. `keys[i]` corresponds to
 * `values[i]`.
 *
 * Free with native_string_map_free(); it releases every entry and the arrays.
 */
typedef struct {
  char** keys;
  char** values;
  long count;
} native_string_map_t;

/**
 * Convert a C++ string to a C string with memory allocation
 * @param str The C++ string to convert
 * @return Allocated C string copy, or nullptr if str is empty or allocation
 * failed. Caller must free the returned string with free_c_str().
 */
#ifdef __cplusplus
char* to_c_str(const std::string& str);

/**
 * Convert a C++ string vector to an owning C string list.
 * @param values The strings to copy
 * @return List owned by the caller; free it with native_string_list_free().
 */
native_string_list_t to_c_string_list(const std::vector<std::string>& values);

/**
 * Convert a C++ string map to an owning C string map.
 * @param values The entries to copy
 * @return Map owned by the caller; free it with native_string_map_free().
 */
native_string_map_t to_c_string_map(const std::map<std::string, std::string>& values);
#endif

/**
 * Free a C string allocated by to_c_str
 * @param str The string to free (can be nullptr)
 */
FFI_PLUGIN_EXPORT
void free_c_str(char* str);

/**
 * Free a string list allocated by to_c_string_list
 * @param list The list to free (can be nullptr)
 */
FFI_PLUGIN_EXPORT
void native_string_list_free(native_string_list_t* list);

/**
 * Free a string map allocated by to_c_string_map
 * @param map The map to free (can be nullptr)
 */
FFI_PLUGIN_EXPORT
void native_string_map_free(native_string_map_t* map);

#ifdef __cplusplus
}
#endif
