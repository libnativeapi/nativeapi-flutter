#pragma once

namespace nativeapi {

/**
 * @brief Placement options for positioning UI elements relative to an anchor.
 *
 * Defines how a UI element (such as a menu, tooltip, or popover) should be
 * positioned relative to an anchor element or point. The placement consists
 * of a primary direction (top, right, bottom, left) and an optional alignment
 * (start, center, end).
 *
 * Primary directions:
 * - Top: Element appears above the anchor
 * - Right: Element appears to the right of the anchor
 * - Bottom: Element appears below the anchor
 * - Left: Element appears to the left of the anchor
 *
 * Alignments:
 * - Start: Element aligns to the start edge (left for horizontal, top for vertical)
 * - Center: Element centers along the anchor (default if not specified)
 * - End: Element aligns to the end edge (right for horizontal, bottom for vertical)
 *
 * @example
 * ```cpp
 * // Position menu below the button, aligned to the left
 * menu->Open(PositioningStrategy::Absolute({100, 100}), Placement::BottomStart);
 *
 * // Position popover to the right, aligned to the top
 * popover->Open(PositioningStrategy::CursorPosition(), Placement::RightStart);
 * ```
 */
enum class Placement {
  /**
   * Position above the anchor, horizontally centered.
   */
  Top,

  /**
   * Position above the anchor, aligned to the start (left).
   */
  TopStart,

  /**
   * Position above the anchor, aligned to the end (right).
   */
  TopEnd,

  /**
   * Position to the right of the anchor, vertically centered.
   */
  Right,

  /**
   * Position to the right of the anchor, aligned to the start (top).
   */
  RightStart,

  /**
   * Position to the right of the anchor, aligned to the end (bottom).
   */
  RightEnd,

  /**
   * Position below the anchor, horizontally centered.
   */
  Bottom,

  /**
   * Position below the anchor, aligned to the start (left).
   */
  BottomStart,

  /**
   * Position below the anchor, aligned to the end (right).
   */
  BottomEnd,

  /**
   * Position to the left of the anchor, vertically centered.
   */
  Left,

  /**
   * Position to the left of the anchor, aligned to the start (top).
   */
  LeftStart,

  /**
   * Position to the left of the anchor, aligned to the end (bottom).
   */
  LeftEnd
};

}  // namespace nativeapi
