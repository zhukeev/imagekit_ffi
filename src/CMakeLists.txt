cmake_minimum_required(VERSION 3.10)
project(imagekit_ffi_library VERSION 0.0.1 LANGUAGES C CXX)

# Основная библиотека
add_library(imagekit_ffi SHARED
  imagekit_ffi.c
)

target_include_directories(imagekit_ffi PRIVATE
  ${CMAKE_CURRENT_SOURCE_DIR}/../third_party/libjpeg-turbo/include
)


# --- iOS/macOS (system libjpeg-turbo) ---
if(NOT ANDROID)
  find_path(JPEG_INCLUDE_DIR turbojpeg.h)
  find_library(JPEG_LIBRARY turbojpeg)

  if(JPEG_INCLUDE_DIR AND JPEG_LIBRARY)
    message(STATUS "Found libjpeg-turbo: ${JPEG_LIBRARY}")
    target_include_directories(imagekit_ffi PRIVATE ${JPEG_INCLUDE_DIR})
    target_link_libraries(imagekit_ffi PRIVATE ${JPEG_LIBRARY})
  else()
    message(FATAL_ERROR "libjpeg-turbo not found on system.")
  endif()
endif()

# --- Android: локальный .so файл ---
if(ANDROID)
  set(JPEG_TURBO_SO ${CMAKE_CURRENT_SOURCE_DIR}/../third_party/libjpeg-turbo/${ANDROID_ABI}/libturbojpeg.so)
  message(STATUS "Using JPEG turbo .so: ${JPEG_TURBO_SO}")

  target_link_libraries(imagekit_ffi
    ${JPEG_TURBO_SO}
    log
  )
endif()

# Настройки
set_target_properties(imagekit_ffi PROPERTIES
  OUTPUT_NAME "imagekit_ffi"
  PUBLIC_HEADER imagekit_ffi.h
)

target_compile_definitions(imagekit_ffi PUBLIC DART_SHARED_LIB)

if (ANDROID)
  # Support Android 15 16k page size.
  target_link_options(imagekit_ffi PRIVATE "-Wl,-z,max-page-size=16384")
endif()
