#pragma once
#include "foundation/geometry.h"

namespace nativeapi {

// Forward declaration
class Window;

/**
 * @brief Strategy for determining where to position UI elements.
 *
 * PositioningStrategy defines how to calculate the position for UI elements
 * such as menus, tooltips, or popovers. It supports various positioning modes:
 * - Absolute: Fixed screen coordinates
 * - CursorPosition: Current mouse cursor position
 * - Relative: Position relative to a rectangle
 *
 * @example
 * ```cpp
 * // Position menu at absolute screen coordinates
 * menu->Open(PositioningStrategy::Absolute({100, 200}));
 *
 * // Position menu at current mouse location
 * menu->Open(PositioningStrategy::CursorPosition());
 *
 * // Position menu relative to a rectangle with offset
 * Rectangle buttonRect = button->GetBounds();
 * menu->Open(PositioningStrategy::Relative(buttonRect, {0, 10}));
 * ```
 */
class PositioningStrategy {
 public:
  /**
   * @brief Type of positioning strategy.
   */
  enum class Type {
    /**
     * Position at fixed screen coordinates.
     */
    Absolute,

    /**
     * Position at current mouse cursor location.
     */
    CursorPosition,

    /**
     * Position relative to a rectangle.
     */
    Relative
  };

  /**
   * @brief Create a strategy for absolute positioning at fixed coordinates.
   *
   * @param point Point in screen coordinates
   * @return PositioningStrategy configured for absolute positioning
   *
   * @example
   * ```cpp
   * auto strategy = PositioningStrategy::Absolute({100, 200});
   * menu->Open(strategy, Placement::Bottom);
   * ```
   */
  static PositioningStrategy Absolute(const Point& point);

  /**
   * @brief Create a strategy for positioning at current mouse location.
   *
   * @return PositioningStrategy configured to use mouse cursor position
   *
   * @example
   * ```cpp
   * auto strategy = PositioningStrategy::CursorPosition();
   * contextMenu->Open(strategy, Placement::BottomStart);
   * ```
   */
  static PositioningStrategy CursorPosition();

  /**
   * @brief Create a strategy for positioning relative to a rectangle.
   *
   * @param rect Rectangle in screen coordinates to position relative to
   * @param offset Optional offset point to apply to the position (default: {0, 0})
   * @return PositioningStrategy configured for rectangle-relative positioning
   *
   * @example
   * ```cpp
   * Rectangle buttonRect = button->GetBounds();
   * // Position at bottom of button (no offset)
   * auto strategy = PositioningStrategy::Relative(buttonRect, {0, 0});
   * menu->Open(strategy);
   *
   * // Position at bottom of button with 10px vertical offset
   * auto strategy2 = PositioningStrategy::Relative(buttonRect, {0, 10});
   * menu->Open(strategy2);
   * ```
   */
  static PositioningStrategy Relative(const Rectangle& rect, const Point& offset = {0, 0});

  /**
   * @brief Create a strategy for positioning relative to a window.
   *
   * @param window Window to position relative to
   * @param offset Optional offset point to apply to the position (default: {0, 0})
   * @return PositioningStrategy configured for window-relative positioning
   *
   * This method stores a reference to the window and will obtain its bounds
   * dynamically when GetRelativeRectangle() is called, ensuring the position
   * reflects the window's current state.
   *
   * @example
   * ```cpp
   * auto window = WindowManager::GetInstance().Create(options);
   * // Position menu at bottom of window (no offset)
   * auto strategy = PositioningStrategy::Relative(*window, {0, 0});
   * menu->Open(strategy);
   *
   * // Position menu at bottom of window with 10px vertical offset
   * auto strategy2 = PositioningStrategy::Relative(*window, {0, 10});
   * menu->Open(strategy2);
   * ```
   */
  static PositioningStrategy Relative(const Window& window, const Point& offset = {0, 0});

  /**
   * @brief Get the type of this positioning strategy.
   *
   * @return The Type enum value indicating the strategy type
   */
  Type GetType() const { return type_; }

  /**
   * @brief Get the absolute position (for Absolute type).
   *
   * @return Point containing x,y coordinates
   * @note Only valid when GetType() == Type::Absolute
   */
  Point GetAbsolutePosition() const { return absolute_position_; }

  /**
   * @brief Get the relative rectangle (for Relative type).
   *
   * @return Rectangle in screen coordinates
   * @note Only valid when GetType() == Type::Relative
   * @note If the strategy was created with a Window, this will return the
   *       window's current bounds (obtained dynamically).
   */
  Rectangle GetRelativeRectangle() const;

  /**
   * @brief Get the relative offset point (for Relative type).
   *
   * @return Point containing x,y relative offset
   * @note Only valid when GetType() == Type::Relative
   */
  Point GetRelativeOffset() const { return relative_offset_; }

  /**
   * @brief Get the relative window (for Relative type created with Window).
   *
   * @return Pointer to the Window, or nullptr if not set
   * @note Only valid when GetType() == Type::Relative and strategy was created with a Window
   */
  const Window* GetRelativeWindow() const { return relative_window_; }

 private:
  /**
   * @brief Private constructor - use static factory methods instead.
   */
  PositioningStrategy(Type type);

  Type type_;
  Point absolute_position_;
  Rectangle relative_rect_;
  Point relative_offset_;
  const Window* relative_window_;
};

}  // namespace nativeapi
