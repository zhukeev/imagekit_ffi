cmake_minimum_required(VERSION 3.10)

project(imagekit_ffi_library VERSION 0.0.1 LANGUAGES C)

add_library(imagekit_ffi SHARED
  "imagekit_ffi.c"
)

set(JPEG_TURBO_ROOT ${PROJECT_SOURCE_DIR}/../third_party/libjpeg-turbo)
set(JPEG_TURBO_INCLUDE_DIR ${JPEG_TURBO_ROOT}/src)

# --- Platform-specific lib path ---
if(ANDROID)
  if(${ANDROID_ABI} STREQUAL "armeabi-v7a")
    set(JPEG_TURBO_LIB ${JPEG_TURBO_ROOT}/build-android-armeabi-v7a/libjpeg.a)
  elseif(${ANDROID_ABI} STREQUAL "arm64-v8a")
    set(JPEG_TURBO_LIB ${JPEG_TURBO_ROOT}/build-android-arm64-v8a/libjpeg.a)
  elseif(${ANDROID_ABI} STREQUAL "x86")
    set(JPEG_TURBO_LIB ${JPEG_TURBO_ROOT}/build-android-x86/libjpeg.a)
  elseif(${ANDROID_ABI} STREQUAL "x86_64")
    set(JPEG_TURBO_LIB ${JPEG_TURBO_ROOT}/build-android-x86_64/libjpeg.a)
  else()
    message(FATAL_ERROR "Unsupported ANDROID_ABI: ${ANDROID_ABI}")
  endif()

  include_directories(${JPEG_TURBO_INCLUDE_DIR})
  target_link_libraries(imagekit_ffi PRIVATE ${JPEG_TURBO_LIB})

  # Android 16k page size support
  target_link_options(imagekit_ffi PRIVATE "-Wl,-z,max-page-size=16384")

elseif(APPLE AND NOT ANDROID)
  set(JPEG_TURBO_LIB ${JPEG_TURBO_ROOT}/build-ios/Release-iphoneos/libjpeg.a)

  include_directories(${JPEG_TURBO_INCLUDE_DIR})
  target_link_libraries(imagekit_ffi PRIVATE ${JPEG_TURBO_LIB})
endif()

# --- Plugin settings ---
set_target_properties(imagekit_ffi PROPERTIES
  PUBLIC_HEADER imagekit_ffi.h
  OUTPUT_NAME "imagekit_ffi"
)

target_compile_definitions(imagekit_ffi PUBLIC DART_SHARED_LIB)
