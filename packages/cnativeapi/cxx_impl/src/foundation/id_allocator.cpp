/**
 * Implementation of IdAllocator static methods for ID querying and validation.
 */

#include "id_allocator.h"

namespace nativeapi {

/**
 * Extracts the type from an ID.
 */
uint32_t IdAllocator::GetType(IdType id) {
  // Extract type value from high 8 bits (bits 31-24)
  // kTypeMask = 0xFF000000, kTypeShift = 24
  const uint32_t type_value = (id & kTypeMask) >> kTypeShift;
  return type_value;
}

/**
 * Extracts the sequence number from an ID.
 */
uint32_t IdAllocator::GetSequence(IdType id) {
  // Extract sequence number from low 24 bits (bits 23-0)
  // kSequenceMask = 0x00FFFFFF
  return id & kSequenceMask;
}

/**
 * Checks if an ID is valid.
 */
bool IdAllocator::IsValid(IdType id) {
  // Extract type value from high 8 bits
  const uint32_t type_value = (id & kTypeMask) >> kTypeShift;

  // Extract sequence number from low 24 bits
  const uint32_t seq = id & kSequenceMask;

  // ID is valid if:
  // 1. Type value is in valid range [kMinTypeValue, kMaxTypeValue] (1-10)
  // 2. Sequence number is non-zero (0 is reserved for kInvalidId)
  return IsValidType(type_value) && seq != 0u;
}

/**
 * Extracts both type and sequence from an ID.
 */
std::pair<uint32_t, uint32_t> IdAllocator::Decompose(IdType id) {
  // Extract type value from high 8 bits (bits 31-24)
  const uint32_t type_value = (id & kTypeMask) >> kTypeShift;

  // Extract sequence number from low 24 bits (bits 23-0)
  const uint32_t sequence = id & kSequenceMask;

  // Return both components as a pair
  return {type_value, sequence};
}

}  // namespace nativeapi
