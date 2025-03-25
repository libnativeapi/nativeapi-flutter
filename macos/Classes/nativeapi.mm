// Relative import to be able to reuse the C sources.
// See the comment in ../nativeapi.podspec for more information.

// Import Cocoa framework
#import <Cocoa/Cocoa.h>

// Include source files
#include "../../src/nativeapi.cpp"
#include "../../src/libnativeapi/src/screen_retriever.cpp"
#include "../../src/libnativeapi/src/screen_retriever_macos.mm"