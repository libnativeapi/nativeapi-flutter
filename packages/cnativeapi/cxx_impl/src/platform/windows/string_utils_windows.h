#ifndef NATIVEAPI_PLATFORM_WINDOWS_STRING_UTILS_H_
#define NATIVEAPI_PLATFORM_WINDOWS_STRING_UTILS_H_

#include <windows.h>
#include <string>

namespace nativeapi {
namespace {  // Anonymous namespace, visible only within the translation unit including this header

// Convert std::string (UTF-8) to std::wstring (UTF-16)
inline std::wstring StringToWString(const std::string& str) {
  if (str.empty())
    return std::wstring();

  int size_needed = MultiByteToWideChar(CP_UTF8, 0, str.c_str(), (int)str.size(), nullptr, 0);
  std::wstring wstr(size_needed, 0);
  MultiByteToWideChar(CP_UTF8, 0, str.c_str(), (int)str.size(), &wstr[0], size_needed);
  return wstr;
}

// Convert std::wstring (UTF-16) to std::string (UTF-8)
inline std::string WStringToString(const std::wstring& wstr) {
  if (wstr.empty())
    return std::string();

  int size_needed =
      WideCharToMultiByte(CP_UTF8, 0, wstr.c_str(), (int)wstr.size(), nullptr, 0, nullptr, nullptr);
  std::string str(size_needed, 0);
  WideCharToMultiByte(CP_UTF8, 0, wstr.c_str(), (int)wstr.size(), &str[0], size_needed, nullptr,
                      nullptr);
  return str;
}

// Convert WCHAR array to std::string
inline std::string WCharArrayToString(const WCHAR* wchar_array) {
  if (!wchar_array)
    return std::string();
  return WStringToString(std::wstring(wchar_array));
}

}  // anonymous namespace
}  // namespace nativeapi

#endif  // NATIVEAPI_PLATFORM_WINDOWS_STRING_UTILS_H_
