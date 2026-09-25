#include "napi_support.h"

#include <atomic>
#include <chrono>
#include <condition_variable>
#include <memory>
#include <mutex>
#include <thread>

#include "foundation/dispatcher.h"

namespace nativeapi_js {

namespace {

std::thread::id g_js_thread;
// Cleared when the environment tears down. Native code can still fire events
// during process exit (windows closing, static destructors); by then calling
// into the engine would crash.
std::atomic<bool> g_env_alive{false};
bool g_hop_to_main_thread = false;

bool IsJsThread() {
  return std::this_thread::get_id() == g_js_thread;
}

bool Throw(napi_env env, const std::string& message) {
  napi_throw_type_error(env, nullptr, message.c_str());
  return false;
}

bool TypeIs(napi_env env, napi_value value, napi_valuetype expected) {
  napi_valuetype type = napi_undefined;
  return napi_typeof(env, value, &type) == napi_ok && type == expected;
}

}  // namespace

// ---------------------------------------------------------------------------
// Value
// ---------------------------------------------------------------------------

Value Value::Bool(bool value) {
  Value result(Kind::kBool);
  result.bool_ = value;
  return result;
}

Value Value::Number(double value) {
  Value result(Kind::kNumber);
  result.number_ = value;
  return result;
}

Value Value::BigInt(uint64_t value) {
  Value result(Kind::kBigInt);
  result.bigint_ = value;
  return result;
}

Value Value::String(const char* value) {
  if (value == nullptr) {
    return Null();
  }
  return String(std::string(value));
}

Value Value::String(std::string value) {
  Value result(Kind::kString);
  result.string_ = std::move(value);
  return result;
}

Value& Value::Push(Value item) {
  items_.push_back(std::move(item));
  return *this;
}

Value& Value::Set(std::string key, Value item) {
  fields_.emplace_back(std::move(key), std::move(item));
  return *this;
}

napi_value Value::ToJs(napi_env env) const {
  napi_value result = nullptr;
  switch (kind_) {
    case Kind::kUndefined:
      napi_get_undefined(env, &result);
      break;
    case Kind::kNull:
      napi_get_null(env, &result);
      break;
    case Kind::kBool:
      napi_get_boolean(env, bool_, &result);
      break;
    case Kind::kNumber:
      napi_create_double(env, number_, &result);
      break;
    case Kind::kBigInt:
      napi_create_bigint_uint64(env, bigint_, &result);
      break;
    case Kind::kString:
      napi_create_string_utf8(env, string_.data(), string_.size(), &result);
      break;
    case Kind::kArray:
      napi_create_array_with_length(env, items_.size(), &result);
      for (size_t i = 0; i < items_.size(); ++i) {
        napi_set_element(env, result, static_cast<uint32_t>(i), items_[i].ToJs(env));
      }
      break;
    case Kind::kObject:
      napi_create_object(env, &result);
      for (const auto& [key, item] : fields_) {
        napi_set_named_property(env, result, key.c_str(), item.ToJs(env));
      }
      break;
  }
  return result;
}

Value CopyStringList(const native_string_list_t& list) {
  Value result = Value::Array();
  for (long i = 0; list.items != nullptr && i < list.count; ++i) {
    result.Push(Value::String(list.items[i] ? list.items[i] : ""));
  }
  return result;
}

Value CopyStringMap(const native_string_map_t& map) {
  Value result = Value::Object();
  for (long i = 0; map.keys != nullptr && map.values != nullptr && i < map.count; ++i) {
    if (map.keys[i] != nullptr) {
      result.Set(map.keys[i], Value::String(map.values[i] ? map.values[i] : ""));
    }
  }
  return result;
}

// ---------------------------------------------------------------------------
// Arguments
// ---------------------------------------------------------------------------

Args::Args(napi_env env, napi_callback_info info) : env_(env) {
  ok_ = napi_get_cb_info(env, info, &count_, argv_, nullptr, nullptr) == napi_ok;
  if (count_ > kMaxArgs) {
    count_ = kMaxArgs;
  }
}

napi_value Args::operator[](size_t index) const {
  if (index < count_ && argv_[index] != nullptr) {
    return argv_[index];
  }
  return Undefined(env_);
}

char* Arena::Keep(std::string value) {
  strings_.push_back(std::move(value));
  return strings_.back().data();
}

char** Arena::KeepArray(std::vector<char*> items) {
  arrays_.push_back(std::move(items));
  return arrays_.back().data();
}

napi_value Undefined(napi_env env) {
  napi_value result = nullptr;
  napi_get_undefined(env, &result);
  return result;
}

bool IsNullish(napi_env env, napi_value value) {
  napi_valuetype type = napi_undefined;
  napi_typeof(env, value, &type);
  return type == napi_undefined || type == napi_null;
}

bool ExpectObject(napi_env env, napi_value value, const char* type_name) {
  if (!TypeIs(env, value, napi_object)) {
    return Throw(env, std::string("expected a ") + type_name + " object");
  }
  return true;
}

bool GetField(napi_env env, napi_value object, const char* name, napi_value* out) {
  napi_value field = nullptr;
  if (napi_get_named_property(env, object, name, &field) != napi_ok) {
    return false;
  }
  *out = TypeIs(env, field, napi_undefined) ? nullptr : field;
  return true;
}

bool GetBool(napi_env env, napi_value value, bool* out) {
  if (napi_get_value_bool(env, value, out) != napi_ok) {
    return Throw(env, "expected a boolean");
  }
  return true;
}

bool GetDouble(napi_env env, napi_value value, double* out) {
  if (TypeIs(env, value, napi_bigint)) {
    int64_t number = 0;
    bool lossless = false;
    napi_get_value_bigint_int64(env, value, &number, &lossless);
    *out = static_cast<double>(number);
    return true;
  }
  if (napi_get_value_double(env, value, out) != napi_ok) {
    return Throw(env, "expected a number");
  }
  return true;
}

bool GetHandle(napi_env env, napi_value value, uint64_t* out) {
  if (IsNullish(env, value)) {
    *out = 0;
    return true;
  }
  if (TypeIs(env, value, napi_bigint)) {
    bool lossless = false;
    napi_get_value_bigint_uint64(env, value, out, &lossless);
    return true;
  }
  double number = 0;
  if (napi_get_value_double(env, value, &number) != napi_ok) {
    return Throw(env, "expected a handle (bigint)");
  }
  *out = static_cast<uint64_t>(number);
  return true;
}

bool GetPointer(napi_env env, napi_value value, void** out) {
  uint64_t address = 0;
  if (!GetHandle(env, value, &address)) {
    return false;
  }
  *out = reinterpret_cast<void*>(static_cast<uintptr_t>(address));
  return true;
}

bool GetString(napi_env env, napi_value value, Arena& arena, char** out) {
  size_t length = 0;
  if (napi_get_value_string_utf8(env, value, nullptr, 0, &length) != napi_ok) {
    return Throw(env, "expected a string");
  }
  std::string buffer(length, '\0');
  napi_get_value_string_utf8(env, value, buffer.data(), length + 1, &length);
  *out = arena.Keep(std::move(buffer));
  return true;
}

bool GetString(napi_env env, napi_value value, Arena& arena, const char** out) {
  char* text = nullptr;
  if (!GetString(env, value, arena, &text)) {
    return false;
  }
  *out = text;
  return true;
}

bool GetOptionalString(napi_env env, napi_value value, Arena& arena, char** out) {
  if (IsNullish(env, value)) {
    *out = nullptr;
    return true;
  }
  return GetString(env, value, arena, out);
}

bool GetOptionalString(napi_env env, napi_value value, Arena& arena, const char** out) {
  char* text = nullptr;
  if (!GetOptionalString(env, value, arena, &text)) {
    return false;
  }
  *out = text;
  return true;
}

bool GetStringList(napi_env env, napi_value value, Arena& arena, native_string_list_t* out) {
  bool is_array = false;
  if (napi_is_array(env, value, &is_array) != napi_ok || !is_array) {
    return Throw(env, "expected an array of strings");
  }
  uint32_t length = 0;
  napi_get_array_length(env, value, &length);
  std::vector<char*> items(length, nullptr);
  for (uint32_t i = 0; i < length; ++i) {
    napi_value item = nullptr;
    napi_get_element(env, value, i, &item);
    if (!GetString(env, item, arena, &items[i])) {
      return false;
    }
  }
  out->items = arena.KeepArray(std::move(items));
  out->count = static_cast<long>(length);
  return true;
}

bool GetStringMap(napi_env env, napi_value value, Arena& arena, native_string_map_t* out) {
  if (!ExpectObject(env, value, "string map")) {
    return false;
  }
  napi_value names = nullptr;
  napi_get_property_names(env, value, &names);
  uint32_t length = 0;
  napi_get_array_length(env, names, &length);
  std::vector<char*> keys(length, nullptr);
  std::vector<char*> values(length, nullptr);
  for (uint32_t i = 0; i < length; ++i) {
    napi_value key = nullptr;
    napi_value item = nullptr;
    napi_get_element(env, names, i, &key);
    napi_get_property(env, value, key, &item);
    if (!GetString(env, key, arena, &keys[i]) || !GetString(env, item, arena, &values[i])) {
      return false;
    }
  }
  out->keys = arena.KeepArray(std::move(keys));
  out->values = arena.KeepArray(std::move(values));
  out->count = static_cast<long>(length);
  return true;
}

// ---------------------------------------------------------------------------
// Callbacks
// ---------------------------------------------------------------------------

namespace {

// Queued in place of call arguments: release the Callback instead.
char g_release_marker;

void ReportException(napi_env env) {
  bool pending = false;
  if (napi_is_exception_pending(env, &pending) != napi_ok || !pending) {
    return;
  }
  napi_value error = nullptr;
  napi_get_and_clear_last_exception(env, &error);
  // Same as an exception thrown from any other event handler: it surfaces as
  // an uncaught exception rather than vanishing inside native code.
  napi_fatal_exception(env, error);
}

}  // namespace

bool GetCallback(napi_env env, napi_value value, bool optional, Callback** out) {
  *out = nullptr;
  if (optional && IsNullish(env, value)) {
    return true;
  }
  if (!TypeIs(env, value, napi_function)) {
    return Throw(env, "expected a function");
  }
  auto* callback = new Callback();
  callback->env_ = env;
  napi_create_reference(env, value, 1, &callback->function_);

  napi_value name = nullptr;
  napi_create_string_utf8(env, "nativeapi callback", NAPI_AUTO_LENGTH, &name);
  // The queue owns the Callback: its finalizer frees it once released and
  // drained, so a call still queued never touches freed memory.
  auto finalize = [](napi_env, void* data, void*) { delete static_cast<Callback*>(data); };
  if (napi_create_threadsafe_function(env, nullptr, nullptr, name, 0, 1, callback, finalize,
                                      callback, &Callback::CallFromQueue,
                                      &callback->queue_) == napi_ok) {
    // A registered listener must not keep the process alive on its own.
    napi_unref_threadsafe_function(env, callback->queue_);
  } else {
    callback->queue_ = nullptr;
  }
  *out = callback;
  return true;
}

void Callback::Dispatch(void* user_data, std::vector<Value> args) {
  auto* callback = static_cast<Callback*>(user_data);
  if (callback == nullptr || !g_env_alive.load()) {
    return;
  }
  if (IsJsThread()) {
    // Native code only runs on this thread from inside a call we made (an API
    // call, or the event loop pump), so the engine is in a callable state.
    napi_handle_scope scope = nullptr;
    napi_open_handle_scope(callback->env_, &scope);
    callback->Call(callback->env_, args);
    napi_close_handle_scope(callback->env_, scope);
    return;
  }
  if (callback->queue_ != nullptr) {
    auto* queued = new std::vector<Value>(std::move(args));
    if (napi_call_threadsafe_function(callback->queue_, queued, napi_tsfn_nonblocking) !=
        napi_ok) {
      delete queued;
    }
  }
}

void Callback::CallFromQueue(napi_env env, napi_value, void* context, void* data) {
  if (data == &g_release_marker) {
    if (env != nullptr && g_env_alive.load()) {
      static_cast<Callback*>(context)->ReleaseOnJsThread();
    }
    return;
  }
  auto* args = static_cast<std::vector<Value>*>(data);
  if (env != nullptr && g_env_alive.load()) {
    static_cast<Callback*>(context)->Call(env, *args);
  }
  delete args;
}

void Callback::Call(napi_env env, const std::vector<Value>& args) {
  if (function_ == nullptr) {
    return;
  }
  napi_value function = nullptr;
  if (napi_get_reference_value(env, function_, &function) != napi_ok || function == nullptr) {
    return;
  }
  std::vector<napi_value> argv;
  argv.reserve(args.size());
  for (const auto& arg : args) {
    argv.push_back(arg.ToJs(env));
  }
  napi_value result = nullptr;
  if (napi_call_function(env, Undefined(env), function, argv.size(), argv.data(), &result) !=
      napi_ok) {
    ReportException(env);
  }
}

void Callback::ReleaseUserData(void* user_data) {
  auto* callback = static_cast<Callback*>(user_data);
  if (callback == nullptr || !g_env_alive.load()) {
    return;  // The environment is gone, and every Callback with it.
  }
  if (IsJsThread()) {
    callback->ReleaseOnJsThread();
  } else if (callback->queue_ != nullptr) {
    napi_call_threadsafe_function(callback->queue_, &g_release_marker, napi_tsfn_nonblocking);
  }
}

void Callback::ReleaseOnJsThread() {
  if (function_ != nullptr) {
    napi_delete_reference(env_, function_);
    function_ = nullptr;
  }
  if (queue_ != nullptr) {
    auto* queue = queue_;
    queue_ = nullptr;
    napi_release_threadsafe_function(queue, napi_tsfn_release);  // finalizer frees this
  } else {
    delete this;
  }
}

// ---------------------------------------------------------------------------
// Module setup
// ---------------------------------------------------------------------------

bool NeedsMainThreadHop() {
  return g_hop_to_main_thread && !nativeapi::IsMainThread();
}

void RunOnMainThreadSync(const std::function<void()>& work) {
  std::mutex mutex;
  std::condition_variable done_signal;
  bool done = false;
  bool posted = nativeapi::RunOnMainThread([&] {
    work();
    std::lock_guard<std::mutex> lock(mutex);
    done = true;
    done_signal.notify_one();
  });
  if (!posted) {
    // No UI thread to post to; calling here is the best that is left.
    work();
    return;
  }
  std::unique_lock<std::mutex> lock(mutex);
  done_signal.wait(lock, [&] { return done; });
}

namespace {

// Whether something on the UI thread drains its queue — a host running the
// platform loop, as under `deno desktop`. `deno test` also runs JS off the main
// thread, but its main thread only waits in Deno's own loop: hopping there
// would block forever, so calls stay on the JS thread instead.
bool MainThreadIsServiced() {
  struct Probe {
    std::mutex mutex;
    std::condition_variable signal;
    bool ran = false;
  };
  // Shared, because a late run can land after this returns.
  auto probe = std::make_shared<Probe>();
  bool posted = nativeapi::RunOnMainThread([probe] {
    std::lock_guard<std::mutex> lock(probe->mutex);
    probe->ran = true;
    probe->signal.notify_one();
  });
  if (!posted) {
    return false;
  }
  std::unique_lock<std::mutex> lock(probe->mutex);
  return probe->signal.wait_for(lock, std::chrono::seconds(1), [&] { return probe->ran; });
}

}  // namespace

void InitRuntime(napi_env env) {
  g_js_thread = std::this_thread::get_id();
  g_hop_to_main_thread = !nativeapi::IsMainThread() &&
                         nativeapi::IsMainThreadDispatchSupported() && MainThreadIsServiced();
  g_env_alive.store(true);
  napi_add_env_cleanup_hook(
      env, [](void*) { g_env_alive.store(false); }, nullptr);
}

void Export(napi_env env, napi_value exports, const char* name, napi_callback callback) {
  napi_value function = nullptr;
  napi_create_function(env, name, NAPI_AUTO_LENGTH, callback, nullptr, &function);
  napi_set_named_property(env, exports, name, function);
}

void ExportValue(napi_env env, napi_value exports, const char* name, const Value& value) {
  napi_set_named_property(env, exports, name, value.ToJs(env));
}

}  // namespace nativeapi_js
