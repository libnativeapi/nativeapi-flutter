#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint cnativeapi.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'cnativeapi'
  s.version          = '0.0.1'
  s.summary          = 'A new Flutter FFI plugin project.'
  s.description      = <<-DESC
A new Flutter FFI plugin project.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }

  # This will ensure the source files in Classes/ are included in the native
  # builds of apps using this FFI plugin. Podspec does not support relative
  # paths, so Classes contains a forwarder C file that relatively imports
  # `../cxx_impl/*` so that the C sources can be shared among all target platforms.
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*.{cpp,h,mm}', '../cxx_impl/**/*.{cpp,h,mm}'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 
    'DEFINES_MODULE' => 'YES', 
    # Configure to compile .cpp files as Objective-C++
    'CLANG_ENABLE_OBJC_ARC' => 'YES',
    'CLANG_CXX_LANGUAGE_STANDARD' => 'c++17',
    'CLANG_CXX_LIBRARY' => 'libc++',
    'OTHER_CPLUSPLUSFLAGS' => '-std=c++17',
    # Enable Objective-C++ compilation for .cpp files
    'OTHER_CFLAGS' => '-DOBJC_OLD_DISPATCH_PROTOTYPES=0',
    'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited)',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
  }
  s.swift_version = '5.0'
  
  # Explicitly set file types to compile as Objective-C++
  s.compiler_flags = '-x objective-c++'
end
