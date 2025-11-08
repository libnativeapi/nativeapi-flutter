#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint cnativeapi.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'cnativeapi'
  s.version          = '0.0.1'
  s.summary          = 'A new Flutter plugin project.'
  s.description      = <<-DESC
A new Flutter plugin project.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'cnativeapi/Sources/cnativeapi/**/*', '../cxx_impl/**/*.{cpp,h,mm}'
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

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'cnativeapi_privacy' => ['cnativeapi/Sources/cnativeapi/PrivacyInfo.xcprivacy']}
end
