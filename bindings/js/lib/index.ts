// Public entry point: every generated module, plus the pieces of the runtime
// application code may need.
export * from "./modules.ts";
export { isHostedEventLoop, NativeObject } from "./runtime.ts";
