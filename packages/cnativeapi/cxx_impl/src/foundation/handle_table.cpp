#include "handle_table.h"

namespace nativeapi {

HandleTable& HandleTable::GetInstance() {
  static HandleTable instance;
  return instance;
}

HandleValue HandleTable::InsertErased(std::shared_ptr<void> object, uint32_t type_tag) {
  std::lock_guard<std::mutex> lock(mutex_);

  uint32_t slot_index;
  if (!free_slots_.empty()) {
    slot_index = free_slots_.back();
    free_slots_.pop_back();
  } else {
    slot_index = static_cast<uint32_t>(slots_.size());
    slots_.emplace_back();
  }

  Slot& slot = slots_[slot_index];
  slot.type_tag = type_tag;
  slot.object = std::move(object);

  return Encode(slot.generation, slot_index);
}

const HandleTable::Slot* HandleTable::FindLiveSlotLocked(HandleValue handle) const {
  if (handle == kInvalidHandle) {
    return nullptr;
  }

  const uint32_t slot_index = SlotOf(handle);
  if (slot_index >= slots_.size()) {
    return nullptr;
  }

  const Slot& slot = slots_[slot_index];
  if (!slot.object) {
    return nullptr;  // Slot was released.
  }
  if (slot.generation != GenerationOf(handle)) {
    return nullptr;  // Stale handle to a slot that has since been reused.
  }
  return &slot;
}

std::shared_ptr<void> HandleTable::ResolveErased(HandleValue handle, uint32_t type_tag) const {
  std::lock_guard<std::mutex> lock(mutex_);

  const Slot* slot = FindLiveSlotLocked(handle);
  if (!slot) {
    return nullptr;
  }
  if (slot->type_tag != type_tag) {
    return nullptr;  // Handle confusion: right slot, wrong type.
  }

  // Returning a copy, not a reference: the caller's strong reference must
  // outlive any concurrent Release().
  return slot->object;
}

bool HandleTable::Release(HandleValue handle) {
  // Deliberately deferred past the lock: dropping the last reference runs the
  // object's destructor, which may call back into the table (a Window releasing
  // child handles, say). Doing that under mutex_ would self-deadlock.
  std::shared_ptr<void> doomed;

  {
    std::lock_guard<std::mutex> lock(mutex_);

    if (!FindLiveSlotLocked(handle)) {
      return false;
    }

    const uint32_t slot_index = SlotOf(handle);
    Slot& slot = slots_[slot_index];

    doomed = std::move(slot.object);
    slot.object = nullptr;
    slot.type_tag = 0;

    // Invalidate every outstanding handle to this slot. Skip 0 on wraparound so
    // Encode(generation, 0) can never equal kInvalidHandle.
    ++slot.generation;
    if (slot.generation == 0) {
      slot.generation = 1;
    }

    free_slots_.push_back(slot_index);
  }

  return true;
}

bool HandleTable::Contains(HandleValue handle) const {
  std::lock_guard<std::mutex> lock(mutex_);
  return FindLiveSlotLocked(handle) != nullptr;
}

uint32_t HandleTable::GetTypeTag(HandleValue handle) const {
  std::lock_guard<std::mutex> lock(mutex_);
  const Slot* slot = FindLiveSlotLocked(handle);
  return slot ? slot->type_tag : 0u;
}

size_t HandleTable::LiveCount() const {
  std::lock_guard<std::mutex> lock(mutex_);
  return slots_.size() - free_slots_.size();
}

}  // namespace nativeapi
