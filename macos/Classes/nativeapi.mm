// Relative import to be able to reuse the C sources.
// See the comment in ../nativeapi.podspec for more information.

// Import Cocoa framework
#import <Cocoa/Cocoa.h>

// Include source files
#include "../../src/libnativeapi/src/screen_retriever.cpp"
#include "../../src/libnativeapi/src/screen_retriever_macos.mm"
#include "../../src/libnativeapi/src/window_macos.mm"
#include "../../src/libnativeapi/src/window_manager_macos.mm"

#include "../../src/nativeapi.cpp"
#include "../../src/screen_retriever.cpp"
