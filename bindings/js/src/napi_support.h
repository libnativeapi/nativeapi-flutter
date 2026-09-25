// Runtime shared by the generated N-API glue (src/generated/): argument
// parsing, a plain-data value tree for results and events, and callbacks that
// reach JavaScript from any thread.
#pragma once

#include <node_api.h>

#include <cstddef>
#include <cstdint>
#include <deque>
#include <functional>
#include <string>
#include <type_traits>
#include <utility>
#include <vector>

#include "capi/string_utils_c.h"

namespace nativeapi_js {

// ---------------------------------------------------------------------------
// Value: plain data on its way to JavaScript
// ---------------------------------------------------------------------------

// A JS value built without touching the engine. Converting C data into this
// first means the same converter serves both a synchronous call on the JS
// thread and a hop from another thread, where no napi_env may be used until
// the data reaches the JS thread.
class Value {
 public:
  enum class Kind { kUndefined, kNull, kBool, kNumber, kBigInt, kString, kArray, kObject };

  static Value Undefined() { return Value(Kind::kUndefined); }
  static Value Null() { return Value(Kind::kNull); }
  static Value Bool(bool value);
  static Value Number(double value);
  static Value BigInt(uint64_t value);
  // A null pointer becomes `null`.
  static Value String(const char* value);
  static Value String(std::string value);
  static Value Array() { return Value(Kind::kArray); }
  static Value Object() { return Value(Kind::kObject); }

  Value& Push(Value item);
  Value& Set(std::string key, Value item);

  napi_value ToJs(napi_env env) const;

 private:
  explicit Value(Kind kind) : kind_(kind) {}

  Kind kind_;
  bool bool_ = false;
  double number_ = 0;
  uint64_t bigint_ = 0;
  std::string string_;
  std::vector<Value> items_;
  std::vector<std::pair<std::string, Value>> fields_;
};

// Copies of the C string containers; the caller still frees the original.
Value CopyStringList(const native_string_list_t& list);
Value CopyStringMap(const native_string_map_t& map);

// ---------------------------------------------------------------------------
// Arguments
// ---------------------------------------------------------------------------

// The arguments of one call. Missing trailing arguments read as `undefined`.
class Args {
 public:
  Args(napi_env env, napi_callback_info info);

  bool ok() const { return ok_; }
  napi_value operator[](size_t index) const;

 private:
  static constexpr size_t kMaxArgs = 16;
  napi_env env_;
  bool ok_ = false;
  size_t count_ = kMaxArgs;
  napi_value argv_[kMaxArgs] = {};
};

// Storage that must outlive the C call it feeds: strings and string arrays.
class Arena {
 public:
  char* Keep(std::string value);
  char** KeepArray(std::vector<char*> items);

 private:
  std::deque<std::string> strings_;
  std::deque<std::vector<char*>> arrays_;
};

// Each reader throws a JS TypeError and returns false on a mismatch, so the
// glue can bail out with `return nullptr`.
bool IsNullish(napi_env env, napi_value value);
bool ExpectObject(napi_env env, napi_value value, const char* type_name);
// Reads `object[name]`; `*out` is null when the property is undefined.
bool GetField(napi_env env, napi_value object, const char* name, napi_value* out);

bool GetBool(napi_env env, napi_value value, bool* out);
bool GetDouble(napi_env env, napi_value value, double* out);
// A `bigint` or a number; null and undefined read as the invalid handle 0.
bool GetHandle(napi_env env, napi_value value, uint64_t* out);
bool GetPointer(napi_env env, napi_value value, void** out);
bool GetString(napi_env env, napi_value value, Arena& arena, const char** out);
bool GetString(napi_env env, napi_value value, Arena& arena, char** out);
// Like GetString, but null and undefined read as a null pointer.
bool GetOptionalString(napi_env env, napi_value value, Arena& arena, const char** out);
bool GetOptionalString(napi_env env, napi_value value, Arena& arena, char** out);
bool GetStringList(napi_env env, napi_value value, Arena& arena, native_string_list_t* out);
bool GetStringMap(napi_env env, napi_value value, Arena& arena, native_string_map_t* out);

// Numbers, enums and integer aliases.
template <typename T>
bool GetNumber(napi_env env, napi_value value, T* out) {
  double number = 0;
  if (!GetDouble(env, value, &number)) {
    return false;
  }
  if constexpr (std::is_enum_v<T>) {
    *out = static_cast<T>(static_cast<int64_t>(number));
  } else {
    *out = static_cast<T>(number);
  }
  return true;
}

napi_value Undefined(napi_env env);

// ---------------------------------------------------------------------------
// Callbacks
// ---------------------------------------------------------------------------

// A JS function handed to the C ABI as `user_data`, with ReleaseUserData as
// its release: the core calls that once it can no longer call the function,
// and the Callback is freed then.
class Callback {
 public:
  // `*out` stays null for an optional null/undefined argument.
  friend bool GetCallback(napi_env env, napi_value value, bool optional, Callback** out);

  // Entry point of every generated trampoline. On the JS thread the function
  // runs before this returns; from any other thread the arguments are queued
  // and the function runs on the JS thread later.
  static void Dispatch(void* user_data, std::vector<Value> args);

  // The `native_release_user_data_t` passed with every Callback. The core
  // calls it on the platform main thread, which need not be the JS thread;
  // the JS function is dropped and the Callback freed on the JS thread.
  static void ReleaseUserData(void* user_data);

 private:
  Callback() = default;
  void Call(napi_env env, const std::vector<Value>& args);
  void ReleaseOnJsThread();
  static void CallFromQueue(napi_env env, napi_value js_callback, void* context, void* data);

  napi_env env_ = nullptr;
  napi_ref function_ = nullptr;
  napi_threadsafe_function queue_ = nullptr;
};

bool GetCallback(napi_env env, napi_value value, bool optional, Callback** out);

// ---------------------------------------------------------------------------
// Threads
// ---------------------------------------------------------------------------

// Whether C calls have to hop to the platform UI thread. False under Node,
// Deno and Bun run from a terminal, where JS is on the process main thread.
// True when a host owns the UI thread and runs JS elsewhere — `deno desktop`
// does: its backend runs the platform loop on the main thread.
bool NeedsMainThreadHop();

// Runs `work` on the platform UI thread and waits for it.
void RunOnMainThreadSync(const std::function<void()>& work);

// Every generated glue function makes its C call through this.
template <typename F>
auto OnMainThread(F&& fn) -> decltype(fn()) {
  using Result = decltype(fn());
  if (!NeedsMainThreadHop()) {
    return fn();
  }
  if constexpr (std::is_void_v<Result>) {
    RunOnMainThreadSync([&] { fn(); });
  } else {
    Result result{};
    RunOnMainThreadSync([&] { result = fn(); });
    return result;
  }
}

// ---------------------------------------------------------------------------
// Module setup
// ---------------------------------------------------------------------------

// Records the JS thread and registers the teardown hook; call before anything
// else in the module initializer.
void InitRuntime(napi_env env);

void Export(napi_env env, napi_value exports, const char* name, napi_callback callback);
void ExportValue(napi_env env, napi_value exports, const char* name, const Value& value);

}  // namespace nativeapi_js
