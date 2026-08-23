#include "positioning_strategy.h"
#include "window.h"

namespace nativeapi {

PositioningStrategy::PositioningStrategy(Type type)
    : type_(type),
      absolute_position_{0, 0},
      relative_rect_{0, 0, 0, 0},
      relative_offset_{0, 0},
      relative_window_(nullptr) {}

PositioningStrategy PositioningStrategy::Absolute(const Point& point) {
  PositioningStrategy strategy(Type::Absolute);
  strategy.absolute_position_ = point;
  return strategy;
}

PositioningStrategy PositioningStrategy::CursorPosition() {
  return PositioningStrategy(Type::CursorPosition);
}

PositioningStrategy PositioningStrategy::Relative(const Rectangle& rect, const Point& offset) {
  PositioningStrategy strategy(Type::Relative);
  strategy.relative_rect_ = rect;
  strategy.relative_offset_ = offset;
  strategy.relative_window_ = nullptr;
  return strategy;
}

PositioningStrategy PositioningStrategy::Relative(const Window& window, const Point& offset) {
  PositioningStrategy strategy(Type::Relative);
  strategy.relative_window_ = &window;
  strategy.relative_offset_ = offset;
  // relative_rect_ will be obtained dynamically in GetRelativeRectangle()
  return strategy;
}

Rectangle PositioningStrategy::GetRelativeRectangle() const {
  if (relative_window_) {
    return relative_window_->GetContentBounds();
  }
  return relative_rect_;
}

}  // namespace nativeapi
