# Install script for directory: /Users/argenzhukeev/projects/imagekit_ffi/third_party/libjpeg-turbo

# Set the install prefix
if(NOT DEFINED CMAKE_INSTALL_PREFIX)
  set(CMAKE_INSTALL_PREFIX "/opt/libjpeg-turbo")
endif()
string(REGEX REPLACE "/$" "" CMAKE_INSTALL_PREFIX "${CMAKE_INSTALL_PREFIX}")

# Set the install configuration name.
if(NOT DEFINED CMAKE_INSTALL_CONFIG_NAME)
  if(BUILD_TYPE)
    string(REGEX REPLACE "^[^A-Za-z0-9_]+" ""
           CMAKE_INSTALL_CONFIG_NAME "${BUILD_TYPE}")
  else()
    set(CMAKE_INSTALL_CONFIG_NAME "Release")
  endif()
  message(STATUS "Install configuration: \"${CMAKE_INSTALL_CONFIG_NAME}\"")
endif()

# Set the component getting installed.
if(NOT CMAKE_INSTALL_COMPONENT)
  if(COMPONENT)
    message(STATUS "Install component: \"${COMPONENT}\"")
    set(CMAKE_INSTALL_COMPONENT "${COMPONENT}")
  else()
    set(CMAKE_INSTALL_COMPONENT)
  endif()
endif()

# Install shared libraries without execute permission?
if(NOT DEFINED CMAKE_INSTALL_SO_NO_EXE)
  set(CMAKE_INSTALL_SO_NO_EXE "0")
endif()

# Is this installation the result of a crosscompile?
if(NOT DEFINED CMAKE_CROSSCOMPILING)
  set(CMAKE_CROSSCOMPILING "TRUE")
endif()

# Set default install directory permissions.
if(NOT DEFINED CMAKE_OBJDUMP)
  set(CMAKE_OBJDUMP "/Users/argenzhukeev/Library/Android/sdk/ndk/25.1.8937393/toolchains/llvm/prebuilt/darwin-x86_64/bin/llvm-objdump")
endif()

if(NOT CMAKE_INSTALL_LOCAL_ONLY)
  # Include the install script for the subdirectory.
  include("/Users/argenzhukeev/projects/imagekit_ffi/third_party/libjpeg-turbo/build-android-arm64-v8a/simd/cmake_install.cmake")
endif()

if(NOT CMAKE_INSTALL_LOCAL_ONLY)
  # Include the install script for the subdirectory.
  include("/Users/argenzhukeev/projects/imagekit_ffi/third_party/libjpeg-turbo/build-android-arm64-v8a/sharedlib/cmake_install.cmake")
endif()

if(NOT CMAKE_INSTALL_LOCAL_ONLY)
  # Include the install script for the subdirectory.
  include("/Users/argenzhukeev/projects/imagekit_ffi/third_party/libjpeg-turbo/build-android-arm64-v8a/src/md5/cmake_install.cmake")
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "lib" OR NOT CMAKE_INSTALL_COMPONENT)
  if(EXISTS "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib64/libturbojpeg.so" AND
     NOT IS_SYMLINK "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib64/libturbojpeg.so")
    file(RPATH_CHECK
         FILE "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib64/libturbojpeg.so"
         RPATH "")
  endif()
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib64" TYPE SHARED_LIBRARY FILES "/Users/argenzhukeev/projects/imagekit_ffi/third_party/libjpeg-turbo/build-android-arm64-v8a/libturbojpeg.so")
  if(EXISTS "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib64/libturbojpeg.so" AND
     NOT IS_SYMLINK "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib64/libturbojpeg.so")
    if(CMAKE_INSTALL_DO_STRIP)
      execute_process(COMMAND "/Users/argenzhukeev/Library/Android/sdk/ndk/25.1.8937393/toolchains/llvm/prebuilt/darwin-x86_64/bin/llvm-strip" "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib64/libturbojpeg.so")
    endif()
  endif()
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "lib" OR NOT CMAKE_INSTALL_COMPONENT)
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "bin" OR NOT CMAKE_INSTALL_COMPONENT)
  if(EXISTS "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/bin/tjbench" AND
     NOT IS_SYMLINK "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/bin/tjbench")
    file(RPATH_CHECK
         FILE "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/bin/tjbench"
         RPATH "")
  endif()
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/bin" TYPE EXECUTABLE FILES "/Users/argenzhukeev/projects/imagekit_ffi/third_party/libjpeg-turbo/build-android-arm64-v8a/tjbench")
  if(EXISTS "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/bin/tjbench" AND
     NOT IS_SYMLINK "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/bin/tjbench")
    if(CMAKE_INSTALL_DO_STRIP)
      execute_process(COMMAND "/Users/argenzhukeev/Library/Android/sdk/ndk/25.1.8937393/toolchains/llvm/prebuilt/darwin-x86_64/bin/llvm-strip" "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/bin/tjbench")
    endif()
  endif()
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "lib" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib64" TYPE STATIC_LIBRARY FILES "/Users/argenzhukeev/projects/imagekit_ffi/third_party/libjpeg-turbo/build-android-arm64-v8a/libturbojpeg.a")
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "include" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/include" TYPE FILE FILES "/Users/argenzhukeev/projects/imagekit_ffi/third_party/libjpeg-turbo/src/turbojpeg.h")
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "lib" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib64" TYPE STATIC_LIBRARY FILES "/Users/argenzhukeev/projects/imagekit_ffi/third_party/libjpeg-turbo/build-android-arm64-v8a/libjpeg.a")
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "bin" OR NOT CMAKE_INSTALL_COMPONENT)
  if(EXISTS "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/bin/rdjpgcom" AND
     NOT IS_SYMLINK "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/bin/rdjpgcom")
    file(RPATH_CHECK
         FILE "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/bin/rdjpgcom"
         RPATH "")
  endif()
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/bin" TYPE EXECUTABLE FILES "/Users/argenzhukeev/projects/imagekit_ffi/third_party/libjpeg-turbo/build-android-arm64-v8a/rdjpgcom")
  if(EXISTS "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/bin/rdjpgcom" AND
     NOT IS_SYMLINK "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/bin/rdjpgcom")
    if(CMAKE_INSTALL_DO_STRIP)
      execute_process(COMMAND "/Users/argenzhukeev/Library/Android/sdk/ndk/25.1.8937393/toolchains/llvm/prebuilt/darwin-x86_64/bin/llvm-strip" "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/bin/rdjpgcom")
    endif()
  endif()
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "bin" OR NOT CMAKE_INSTALL_COMPONENT)
  if(EXISTS "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/bin/wrjpgcom" AND
     NOT IS_SYMLINK "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/bin/wrjpgcom")
    file(RPATH_CHECK
         FILE "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/bin/wrjpgcom"
         RPATH "")
  endif()
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/bin" TYPE EXECUTABLE FILES "/Users/argenzhukeev/projects/imagekit_ffi/third_party/libjpeg-turbo/build-android-arm64-v8a/wrjpgcom")
  if(EXISTS "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/bin/wrjpgcom" AND
     NOT IS_SYMLINK "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/bin/wrjpgcom")
    if(CMAKE_INSTALL_DO_STRIP)
      execute_process(COMMAND "/Users/argenzhukeev/Library/Android/sdk/ndk/25.1.8937393/toolchains/llvm/prebuilt/darwin-x86_64/bin/llvm-strip" "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/bin/wrjpgcom")
    endif()
  endif()
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "doc" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/doc" TYPE FILE FILES
    "/Users/argenzhukeev/projects/imagekit_ffi/third_party/libjpeg-turbo/README.ijg"
    "/Users/argenzhukeev/projects/imagekit_ffi/third_party/libjpeg-turbo/README.md"
    "/Users/argenzhukeev/projects/imagekit_ffi/third_party/libjpeg-turbo/src/example.c"
    "/Users/argenzhukeev/projects/imagekit_ffi/third_party/libjpeg-turbo/src/tjcomp.c"
    "/Users/argenzhukeev/projects/imagekit_ffi/third_party/libjpeg-turbo/src/tjdecomp.c"
    "/Users/argenzhukeev/projects/imagekit_ffi/third_party/libjpeg-turbo/src/tjtran.c"
    "/Users/argenzhukeev/projects/imagekit_ffi/third_party/libjpeg-turbo/doc/libjpeg.txt"
    "/Users/argenzhukeev/projects/imagekit_ffi/third_party/libjpeg-turbo/doc/structure.txt"
    "/Users/argenzhukeev/projects/imagekit_ffi/third_party/libjpeg-turbo/doc/usage.txt"
    "/Users/argenzhukeev/projects/imagekit_ffi/third_party/libjpeg-turbo/doc/wizard.txt"
    "/Users/argenzhukeev/projects/imagekit_ffi/third_party/libjpeg-turbo/LICENSE.md"
    )
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "man" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/man/man1" TYPE FILE FILES
    "/Users/argenzhukeev/projects/imagekit_ffi/third_party/libjpeg-turbo/doc/cjpeg.1"
    "/Users/argenzhukeev/projects/imagekit_ffi/third_party/libjpeg-turbo/doc/djpeg.1"
    "/Users/argenzhukeev/projects/imagekit_ffi/third_party/libjpeg-turbo/doc/jpegtran.1"
    "/Users/argenzhukeev/projects/imagekit_ffi/third_party/libjpeg-turbo/doc/rdjpgcom.1"
    "/Users/argenzhukeev/projects/imagekit_ffi/third_party/libjpeg-turbo/doc/wrjpgcom.1"
    )
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "lib" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib64/pkgconfig" TYPE FILE FILES "/Users/argenzhukeev/projects/imagekit_ffi/third_party/libjpeg-turbo/build-android-arm64-v8a/pkgscripts/libjpeg.pc")
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "lib" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib64/pkgconfig" TYPE FILE FILES "/Users/argenzhukeev/projects/imagekit_ffi/third_party/libjpeg-turbo/build-android-arm64-v8a/pkgscripts/libturbojpeg.pc")
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "lib" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib64/cmake/libjpeg-turbo" TYPE FILE FILES
    "/Users/argenzhukeev/projects/imagekit_ffi/third_party/libjpeg-turbo/build-android-arm64-v8a/pkgscripts/libjpeg-turboConfig.cmake"
    "/Users/argenzhukeev/projects/imagekit_ffi/third_party/libjpeg-turbo/build-android-arm64-v8a/pkgscripts/libjpeg-turboConfigVersion.cmake"
    )
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "lib" OR NOT CMAKE_INSTALL_COMPONENT)
  if(EXISTS "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib64/cmake/libjpeg-turbo/libjpeg-turboTargets.cmake")
    file(DIFFERENT _cmake_export_file_changed FILES
         "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib64/cmake/libjpeg-turbo/libjpeg-turboTargets.cmake"
         "/Users/argenzhukeev/projects/imagekit_ffi/third_party/libjpeg-turbo/build-android-arm64-v8a/CMakeFiles/Export/0e6e4b477a4ae71489b37862d1c0227b/libjpeg-turboTargets.cmake")
    if(_cmake_export_file_changed)
      file(GLOB _cmake_old_config_files "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib64/cmake/libjpeg-turbo/libjpeg-turboTargets-*.cmake")
      if(_cmake_old_config_files)
        string(REPLACE ";" ", " _cmake_old_config_files_text "${_cmake_old_config_files}")
        message(STATUS "Old export file \"$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib64/cmake/libjpeg-turbo/libjpeg-turboTargets.cmake\" will be replaced.  Removing files [${_cmake_old_config_files_text}].")
        unset(_cmake_old_config_files_text)
        file(REMOVE ${_cmake_old_config_files})
      endif()
      unset(_cmake_old_config_files)
    endif()
    unset(_cmake_export_file_changed)
  endif()
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib64/cmake/libjpeg-turbo" TYPE FILE FILES "/Users/argenzhukeev/projects/imagekit_ffi/third_party/libjpeg-turbo/build-android-arm64-v8a/CMakeFiles/Export/0e6e4b477a4ae71489b37862d1c0227b/libjpeg-turboTargets.cmake")
  if(CMAKE_INSTALL_CONFIG_NAME MATCHES "^([Rr][Ee][Ll][Ee][Aa][Ss][Ee])$")
    file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib64/cmake/libjpeg-turbo" TYPE FILE FILES "/Users/argenzhukeev/projects/imagekit_ffi/third_party/libjpeg-turbo/build-android-arm64-v8a/CMakeFiles/Export/0e6e4b477a4ae71489b37862d1c0227b/libjpeg-turboTargets-release.cmake")
  endif()
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "include" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/include" TYPE FILE FILES
    "/Users/argenzhukeev/projects/imagekit_ffi/third_party/libjpeg-turbo/build-android-arm64-v8a/jconfig.h"
    "/Users/argenzhukeev/projects/imagekit_ffi/third_party/libjpeg-turbo/src/jerror.h"
    "/Users/argenzhukeev/projects/imagekit_ffi/third_party/libjpeg-turbo/src/jmorecfg.h"
    "/Users/argenzhukeev/projects/imagekit_ffi/third_party/libjpeg-turbo/src/jpeglib.h"
    )
endif()

if(CMAKE_INSTALL_COMPONENT)
  set(CMAKE_INSTALL_MANIFEST "install_manifest_${CMAKE_INSTALL_COMPONENT}.txt")
else()
  set(CMAKE_INSTALL_MANIFEST "install_manifest.txt")
endif()

string(REPLACE ";" "\n" CMAKE_INSTALL_MANIFEST_CONTENT
       "${CMAKE_INSTALL_MANIFEST_FILES}")
file(WRITE "/Users/argenzhukeev/projects/imagekit_ffi/third_party/libjpeg-turbo/build-android-arm64-v8a/${CMAKE_INSTALL_MANIFEST}"
     "${CMAKE_INSTALL_MANIFEST_CONTENT}")
