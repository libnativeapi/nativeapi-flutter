#pragma once

namespace nativeapi {

/**
 * @brief Base class that provides access to platform-specific native objects.
 *
 * This class provides a standardized way for cross-platform wrapper classes
 * to expose their underlying platform-specific objects. Similar to how
 * EventEmitter provides event-related functionality, NativeObjectProvider
 * provides native object access functionality.
 *
 * Classes that inherit from NativeObjectProvider can provide access to:
 * - NSWindow*, NSMenu*, NSMenuItem* on macOS
 * - HWND, HMENU on Windows
 * - GtkWidget*, GtkMenu* on Linux
 *
 * Example usage:
 *
 * class MyWidget : public NativeObjectProvider {
 * public:
 *   MyWidget() : native_widget_(CreatePlatformWidget()) {}
 *
 * protected:
 *   void* GetNativeObjectInternal() const override {
 *     return native_widget_;
 *   }
 *
 * private:
 *   void* native_widget_;
 * };
 *
 * // Usage
 * MyWidget widget;
 * void* native = widget.GetNativeObject();
 *
 * #ifdef __APPLE__
 *   NSView* nsview = (__bridge NSView*)native;
 * #elif defined(_WIN32)
 *   HWND hwnd = (HWND)native;
 * #endif
 */
class NativeObjectProvider {
 public:
  /**
   * @brief Virtual destructor to ensure proper cleanup in derived classes.
   */
  virtual ~NativeObjectProvider() = default;

  /**
   * @brief Get the native platform-specific object.
   *
   * This method provides access to the underlying platform-specific
   * object for advanced use cases. Use with caution as this breaks
   * the abstraction layer.
   *
   * @return Pointer to the native object
   *
   * Platform-specific return types:
   * - macOS: NSWindow*, NSMenu*, NSMenuItem*, NSView*, etc.
   * - Windows: HWND, HMENU, etc.
   * - Linux: GtkWidget*, GtkMenu*, GdkWindow*, etc.
   */
  void* GetNativeObject() const { return GetNativeObjectInternal(); }

 protected:
  /**
   * @brief Internal method to be implemented by derived classes.
   *
   * Derived classes must implement this method to return their
   * platform-specific native object.
   *
   * @return Pointer to the platform-specific native object
   */
  virtual void* GetNativeObjectInternal() const = 0;
};

}  // namespace nativeapi