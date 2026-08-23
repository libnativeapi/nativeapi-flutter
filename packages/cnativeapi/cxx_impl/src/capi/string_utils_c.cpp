#include "string_utils_c.h"
#include <cstring>

char* to_c_str(const std::string& str) {
  if (str.empty())
    return nullptr;

  size_t len = str.length() + 1;
  char* result = new (std::nothrow) char[len];
  if (result) {
    std::strcpy(result, str.c_str());
  }
  return result;
}

native_string_list_t to_c_string_list(const std::vector<std::string>& values) {
  native_string_list_t list = {};
  if (values.empty())
    return list;

  list.items = new (std::nothrow) char*[values.size()]();
  if (!list.items)
    return list;

  for (size_t i = 0; i < values.size(); i++) {
    list.items[i] = to_c_str(values[i]);
  }
  list.count = static_cast<long>(values.size());
  return list;
}

native_string_map_t to_c_string_map(const std::map<std::string, std::string>& values) {
  native_string_map_t map = {};
  if (values.empty())
    return map;

  map.keys = new (std::nothrow) char*[values.size()]();
  map.values = new (std::nothrow) char*[values.size()]();
  if (!map.keys || !map.values) {
    delete[] map.keys;
    delete[] map.values;
    map.keys = nullptr;
    map.values = nullptr;
    return map;
  }

  size_t index = 0;
  for (const auto& entry : values) {
    map.keys[index] = to_c_str(entry.first);
    map.values[index] = to_c_str(entry.second);
    index++;
  }
  map.count = static_cast<long>(values.size());
  return map;
}

void free_c_str(char* str) {
  if (str) {
    delete[] str;
  }
}

void native_string_list_free(native_string_list_t* list) {
  if (!list || !list->items)
    return;

  for (long i = 0; i < list->count; i++) {
    free_c_str(list->items[i]);
  }
  delete[] list->items;
  list->items = nullptr;
  list->count = 0;
}

void native_string_map_free(native_string_map_t* map) {
  if (!map)
    return;

  for (long i = 0; i < map->count; i++) {
    if (map->keys)
      free_c_str(map->keys[i]);
    if (map->values)
      free_c_str(map->values[i]);
  }
  delete[] map->keys;
  delete[] map->values;
  map->keys = nullptr;
  map->values = nullptr;
  map->count = 0;
}
