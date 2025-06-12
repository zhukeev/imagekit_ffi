Pod::Spec.new do |s|
  s.name             = 'imagekit_ffi'
  s.version          = '0.0.1'
  s.summary          = 'ImageKit FFI plugin'
  s.description      = 'Low-level image conversion using libjpeg-turbo'
  s.homepage         = 'https://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Name' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'src/imagekit_ffi.c'
  s.public_header_files = 'src/imagekit_ffi.h'
  s.module_name      = 'imagekit_ffi'

  s.preserve_paths = 'third_party/libjpeg-turbo/build-ios/Release-iphoneos/libjpeg.a'
  s.vendored_libraries = 'third_party/libjpeg-turbo/build-ios/Release-iphoneos/libjpeg.a'
  s.header_mappings_dir = 'src'
  s.requires_arc    = false
end
