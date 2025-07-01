cmake_minimum_required(VERSION 3.10)
# Добавил CXX, так как у вас есть C++ файлы (.cpp)
project(imagekit_ffi_library VERSION 0.0.1 LANGUAGES C CXX)

# Правильный путь для include_directories.
# ${CMAKE_CURRENT_SOURCE_DIR} - это директория, где находится текущий CMakeLists.txt (src/)
# third_party/fpng - это поддиректория внутри src/, поэтому так и указываем.
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/../third_party/fpng)

# Включаем сюда все файлы, которые должны быть скомпилированы в эту общую библиотеку.
add_library(imagekit_ffi SHARED
  imagekit_ffi.c         # Ваш основной FFI файл
  png_wrapper.cpp        # C++ обертка для PNG
  ../third_party/fpng/fpng.cpp # Библиотека fpng
)

# Это должно быть добавлено для всех целевых архитектур x86/x64
target_compile_options(imagekit_ffi PRIVATE
  $<$<CXX_COMPILER_ID:Clang>:-mpclmul -msse4.1> # Для Clang (Android NDK)
  $<$<CXX_COMPILER_ID:GNU>:-mpclmul -msse4.1>  # Для GCC (если вдруг используется)
)

# Определение исполняемого файла для тестов.
# test_png.c - это ваш тестовый файл.
# png_wrapper.cpp и third_party/fpng/fpng.cpp здесь дублируются.
# Если test_png.c вызывает функции из imagekit_ffi (которая теперь включает эти файлы),
# то лучше просто связать test_png с imagekit_ffi.
add_executable(test_png
    test_png.c    # Предполагается, что test_png.c содержит main() и вызывает функции.
)

# Связываем test_png с библиотекой imagekit_ffi.
# Это значит, что test_png может вызывать функции, определенные в imagekit_ffi.c,
# png_wrapper.cpp и fpng.cpp (так как они теперь часть imagekit_ffi).
target_link_libraries(test_png PRIVATE imagekit_ffi)


# --- Plugin settings ---
set_target_properties(imagekit_ffi PROPERTIES
  PUBLIC_HEADER imagekit_ffi.h
  OUTPUT_NAME "imagekit_ffi"
)

target_compile_definitions(imagekit_ffi PUBLIC DART_SHARED_LIB)