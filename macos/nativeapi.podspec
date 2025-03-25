#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint nativeapi.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'nativeapi'
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
  # `../src/*` so that the C sources can be shared among all target platforms.
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*.{cpp,h,mm}', '../src/**/*.{cpp,h,mm}'

  # If your plugin requires a privacy manifest, for example if it collects user
  # data, update the PrivacyInfo.xcprivacy file to describe your plugin's
  # privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'nativeapi_privacy' => ['nativeapi/Sources/nativeapi/PrivacyInfo.xcprivacy']}

  s.dependency 'FlutterMacOS'
  
  # Add Cocoa framework dependency
  s.framework = 'Cocoa'

  s.platform = :osx, '10.11'
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
    'MACOSX_DEPLOYMENT_TARGET' => '10.11'
  }
  s.swift_version = '5.0'
  
  # Explicitly set file types to compile as Objective-C++
  s.compiler_flags = '-x objective-c++'
end
