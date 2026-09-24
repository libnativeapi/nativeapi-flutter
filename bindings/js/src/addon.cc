// Module entry point: the generated C ABI glue plus the event loop pump.
#include <node_api.h>

#include "event_loop.h"
#include "napi_support.h"

namespace nativeapi_js {

void RegisterGenerated(napi_env env, napi_value exports);

namespace {

napi_value JsStartEventLoop(napi_env env, napi_callback_info info) {
  Args args(env, info);
  uint64_t window = 0;
  if (!args.ok() || !GetHandle(env, args[0], &window)) {
    return nullptr;
  }
  StartEventLoop(window);
  return Undefined(env);
}

napi_value JsPumpEventLoop(napi_env env, napi_callback_info) {
  return Value::Number(PumpEventLoop()).ToJs(env);
}

napi_value JsIsMainThread(napi_env env, napi_callback_info) {
  return Value::Bool(IsPlatformMainThread()).ToJs(env);
}

napi_value Init(napi_env env, napi_value exports) {
  InitRuntime(env);
  RegisterGenerated(env, exports);
  Export(env, exports, "startEventLoop", JsStartEventLoop);
  Export(env, exports, "pumpEventLoop", JsPumpEventLoop);
  Export(env, exports, "isMainThread", JsIsMainThread);
  return exports;
}

}  // namespace
}  // namespace nativeapi_js

NAPI_MODULE(nativeapi, nativeapi_js::Init)
