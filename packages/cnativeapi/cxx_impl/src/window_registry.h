#pragma once
#include <memory>
#include <vector>
#include "foundation/id_allocator.h"

namespace nativeapi {

class Window;

using WindowId = IdAllocator::IdType;

class WindowRegistry {
 public:
  static WindowRegistry& GetInstance();

  void Add(WindowId id, const std::shared_ptr<Window>& window);
  std::shared_ptr<Window> Get(WindowId id) const;
  std::vector<std::shared_ptr<Window>> GetAll() const;
  bool Contains(WindowId id) const;
  bool Remove(WindowId id);
  void Clear();

 private:
  WindowRegistry();
  ~WindowRegistry();

  class Impl;
  std::unique_ptr<Impl> pimpl_;
};

}  // namespace nativeapi
