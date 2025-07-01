cmake_minimum_required(VERSION 3.10)
include "../third_party/fpng/fpng.h"

project(imagekit_ffi_library VERSION 0.0.1 LANGUAGES C)

add_library(imagekit_ffi SHARED
  "imagekit_ffi.c"
)

include_directories(${CMAKE_CURRENT_SOURCE_DIR}/../third_party/fpng)

add_library(imagekit SHARED
                imagekit.c
                    png_wrapper.cpp
                    third_party/fpng/fpng.cpp)

add_executable(test_png
    test_png.cpp    
    png_wrapper.cpp
    third_party/fpng/fpng.cpp
)


# --- Plugin settings ---
set_target_properties(imagekit_ffi PROPERTIES
  PUBLIC_HEADER imagekit_ffi.h
  OUTPUT_NAME "imagekit_ffi"
)

target_compile_definitions(imagekit_ffi PUBLIC DART_SHARED_LIB)
