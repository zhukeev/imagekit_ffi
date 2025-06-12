# Install script for directory: /Users/argenzhukeev/projects/imagekit_ffi/third_party/libjpeg-turbo/sharedlib

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

# Is this installation the result of a crosscompile?
if(NOT DEFINED CMAKE_CROSSCOMPILING)
  set(CMAKE_CROSSCOMPILING "TRUE")
endif()

# Set default install directory permissions.
if(NOT DEFINED CMAKE_OBJDUMP)
  set(CMAKE_OBJDUMP "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/objdump")
endif()

set(CMAKE_BINARY_DIR "/Users/argenzhukeev/projects/imagekit_ffi/third_party/libjpeg-turbo/build-ios")

if(NOT PLATFORM_NAME)
  if(NOT "$ENV{PLATFORM_NAME}" STREQUAL "")
    set(PLATFORM_NAME "$ENV{PLATFORM_NAME}")
  endif()
  if(NOT PLATFORM_NAME)
    set(PLATFORM_NAME iphoneos)
  endif()
endif()

if(NOT EFFECTIVE_PLATFORM_NAME)
  if(NOT "$ENV{EFFECTIVE_PLATFORM_NAME}" STREQUAL "")
    set(EFFECTIVE_PLATFORM_NAME "$ENV{EFFECTIVE_PLATFORM_NAME}")
  endif()
  if(NOT EFFECTIVE_PLATFORM_NAME)
    set(EFFECTIVE_PLATFORM_NAME -iphoneos)
  endif()
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "lib" OR NOT CMAKE_INSTALL_COMPONENT)
  if(CMAKE_INSTALL_CONFIG_NAME MATCHES "^([Dd][Ee][Bb][Uu][Gg])$")
    file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib" TYPE SHARED_LIBRARY FILES
      "/Users/argenzhukeev/projects/imagekit_ffi/third_party/libjpeg-turbo/build-ios/Debug/libjpeg.62.4.0.dylib"
      "/Users/argenzhukeev/projects/imagekit_ffi/third_party/libjpeg-turbo/build-ios/Debug/libjpeg.62.dylib"
      )
    foreach(file
        "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libjpeg.62.4.0.dylib"
        "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libjpeg.62.dylib"
        )
      if(EXISTS "${file}" AND
         NOT IS_SYMLINK "${file}")
        execute_process(COMMAND /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/install_name_tool
          -add_rpath "/opt/libjpeg-turbo/lib"
          "${file}")
        if(CMAKE_INSTALL_DO_STRIP)
          execute_process(COMMAND "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/strip" -x "${file}")
        endif()
      endif()
    endforeach()
  elseif(CMAKE_INSTALL_CONFIG_NAME MATCHES "^([Rr][Ee][Ll][Ee][Aa][Ss][Ee])$")
    file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib" TYPE SHARED_LIBRARY FILES
      "/Users/argenzhukeev/projects/imagekit_ffi/third_party/libjpeg-turbo/build-ios/Release/libjpeg.62.4.0.dylib"
      "/Users/argenzhukeev/projects/imagekit_ffi/third_party/libjpeg-turbo/build-ios/Release/libjpeg.62.dylib"
      )
    foreach(file
        "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libjpeg.62.4.0.dylib"
        "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libjpeg.62.dylib"
        )
      if(EXISTS "${file}" AND
         NOT IS_SYMLINK "${file}")
        execute_process(COMMAND /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/install_name_tool
          -add_rpath "/opt/libjpeg-turbo/lib"
          "${file}")
        if(CMAKE_INSTALL_DO_STRIP)
          execute_process(COMMAND "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/strip" -x "${file}")
        endif()
      endif()
    endforeach()
  elseif(CMAKE_INSTALL_CONFIG_NAME MATCHES "^([Mm][Ii][Nn][Ss][Ii][Zz][Ee][Rr][Ee][Ll])$")
    file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib" TYPE SHARED_LIBRARY FILES
      "/Users/argenzhukeev/projects/imagekit_ffi/third_party/libjpeg-turbo/build-ios/MinSizeRel/libjpeg.62.4.0.dylib"
      "/Users/argenzhukeev/projects/imagekit_ffi/third_party/libjpeg-turbo/build-ios/MinSizeRel/libjpeg.62.dylib"
      )
    foreach(file
        "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libjpeg.62.4.0.dylib"
        "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libjpeg.62.dylib"
        )
      if(EXISTS "${file}" AND
         NOT IS_SYMLINK "${file}")
        execute_process(COMMAND /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/install_name_tool
          -add_rpath "/opt/libjpeg-turbo/lib"
          "${file}")
        if(CMAKE_INSTALL_DO_STRIP)
          execute_process(COMMAND "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/strip" -x "${file}")
        endif()
      endif()
    endforeach()
  elseif(CMAKE_INSTALL_CONFIG_NAME MATCHES "^([Rr][Ee][Ll][Ww][Ii][Tt][Hh][Dd][Ee][Bb][Ii][Nn][Ff][Oo])$")
    file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib" TYPE SHARED_LIBRARY FILES
      "/Users/argenzhukeev/projects/imagekit_ffi/third_party/libjpeg-turbo/build-ios/RelWithDebInfo/libjpeg.62.4.0.dylib"
      "/Users/argenzhukeev/projects/imagekit_ffi/third_party/libjpeg-turbo/build-ios/RelWithDebInfo/libjpeg.62.dylib"
      )
    foreach(file
        "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libjpeg.62.4.0.dylib"
        "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libjpeg.62.dylib"
        )
      if(EXISTS "${file}" AND
         NOT IS_SYMLINK "${file}")
        execute_process(COMMAND /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/install_name_tool
          -add_rpath "/opt/libjpeg-turbo/lib"
          "${file}")
        if(CMAKE_INSTALL_DO_STRIP)
          execute_process(COMMAND "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/strip" -x "${file}")
        endif()
      endif()
    endforeach()
  endif()
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "lib" OR NOT CMAKE_INSTALL_COMPONENT)
  if(CMAKE_INSTALL_CONFIG_NAME MATCHES "^([Dd][Ee][Bb][Uu][Gg])$")
    file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib" TYPE SHARED_LIBRARY FILES "/Users/argenzhukeev/projects/imagekit_ffi/third_party/libjpeg-turbo/build-ios/Debug/libjpeg.dylib")
  elseif(CMAKE_INSTALL_CONFIG_NAME MATCHES "^([Rr][Ee][Ll][Ee][Aa][Ss][Ee])$")
    file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib" TYPE SHARED_LIBRARY FILES "/Users/argenzhukeev/projects/imagekit_ffi/third_party/libjpeg-turbo/build-ios/Release/libjpeg.dylib")
  elseif(CMAKE_INSTALL_CONFIG_NAME MATCHES "^([Mm][Ii][Nn][Ss][Ii][Zz][Ee][Rr][Ee][Ll])$")
    file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib" TYPE SHARED_LIBRARY FILES "/Users/argenzhukeev/projects/imagekit_ffi/third_party/libjpeg-turbo/build-ios/MinSizeRel/libjpeg.dylib")
  elseif(CMAKE_INSTALL_CONFIG_NAME MATCHES "^([Rr][Ee][Ll][Ww][Ii][Tt][Hh][Dd][Ee][Bb][Ii][Nn][Ff][Oo])$")
    file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib" TYPE SHARED_LIBRARY FILES "/Users/argenzhukeev/projects/imagekit_ffi/third_party/libjpeg-turbo/build-ios/RelWithDebInfo/libjpeg.dylib")
  endif()
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "bin" OR NOT CMAKE_INSTALL_COMPONENT)
  if(CMAKE_INSTALL_CONFIG_NAME MATCHES "^([Dd][Ee][Bb][Uu][Gg])$")
    file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/bin" TYPE EXECUTABLE FILES "/Users/argenzhukeev/projects/imagekit_ffi/third_party/libjpeg-turbo/build-ios/Debug/cjpeg")
    if(EXISTS "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/bin/cjpeg" AND
       NOT IS_SYMLINK "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/bin/cjpeg")
      execute_process(COMMAND /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/install_name_tool
        -delete_rpath "/Users/argenzhukeev/projects/imagekit_ffi/third_party/libjpeg-turbo/build-ios/Debug"
        -add_rpath "/opt/libjpeg-turbo/lib"
        "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/bin/cjpeg")
      if(CMAKE_INSTALL_DO_STRIP)
        execute_process(COMMAND "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/strip" -u -r "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/bin/cjpeg")
      endif()
    endif()
  elseif(CMAKE_INSTALL_CONFIG_NAME MATCHES "^([Rr][Ee][Ll][Ee][Aa][Ss][Ee])$")
    file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/bin" TYPE EXECUTABLE FILES "/Users/argenzhukeev/projects/imagekit_ffi/third_party/libjpeg-turbo/build-ios/Release/cjpeg")
    if(EXISTS "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/bin/cjpeg" AND
       NOT IS_SYMLINK "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/bin/cjpeg")
      execute_process(COMMAND /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/install_name_tool
        -delete_rpath "/Users/argenzhukeev/projects/imagekit_ffi/third_party/libjpeg-turbo/build-ios/Release"
        -add_rpath "/opt/libjpeg-turbo/lib"
        "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/bin/cjpeg")
      if(CMAKE_INSTALL_DO_STRIP)
        execute_process(COMMAND "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/strip" -u -r "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/bin/cjpeg")
      endif()
    endif()
  elseif(CMAKE_INSTALL_CONFIG_NAME MATCHES "^([Mm][Ii][Nn][Ss][Ii][Zz][Ee][Rr][Ee][Ll])$")
    file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/bin" TYPE EXECUTABLE FILES "/Users/argenzhukeev/projects/imagekit_ffi/third_party/libjpeg-turbo/build-ios/MinSizeRel/cjpeg")
    if(EXISTS "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/bin/cjpeg" AND
       NOT IS_SYMLINK "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/bin/cjpeg")
      execute_process(COMMAND /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/install_name_tool
        -delete_rpath "/Users/argenzhukeev/projects/imagekit_ffi/third_party/libjpeg-turbo/build-ios/MinSizeRel"
        -add_rpath "/opt/libjpeg-turbo/lib"
        "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/bin/cjpeg")
      if(CMAKE_INSTALL_DO_STRIP)
        execute_process(COMMAND "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/strip" -u -r "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/bin/cjpeg")
      endif()
    endif()
  elseif(CMAKE_INSTALL_CONFIG_NAME MATCHES "^([Rr][Ee][Ll][Ww][Ii][Tt][Hh][Dd][Ee][Bb][Ii][Nn][Ff][Oo])$")
    file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/bin" TYPE EXECUTABLE FILES "/Users/argenzhukeev/projects/imagekit_ffi/third_party/libjpeg-turbo/build-ios/RelWithDebInfo/cjpeg")
    if(EXISTS "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/bin/cjpeg" AND
       NOT IS_SYMLINK "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/bin/cjpeg")
      execute_process(COMMAND /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/install_name_tool
        -delete_rpath "/Users/argenzhukeev/projects/imagekit_ffi/third_party/libjpeg-turbo/build-ios/RelWithDebInfo"
        -add_rpath "/opt/libjpeg-turbo/lib"
        "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/bin/cjpeg")
      if(CMAKE_INSTALL_DO_STRIP)
        execute_process(COMMAND "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/strip" -u -r "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/bin/cjpeg")
      endif()
    endif()
  endif()
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "bin" OR NOT CMAKE_INSTALL_COMPONENT)
  if(CMAKE_INSTALL_CONFIG_NAME MATCHES "^([Dd][Ee][Bb][Uu][Gg])$")
    file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/bin" TYPE EXECUTABLE FILES "/Users/argenzhukeev/projects/imagekit_ffi/third_party/libjpeg-turbo/build-ios/Debug/djpeg")
    if(EXISTS "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/bin/djpeg" AND
       NOT IS_SYMLINK "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/bin/djpeg")
      execute_process(COMMAND /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/install_name_tool
        -delete_rpath "/Users/argenzhukeev/projects/imagekit_ffi/third_party/libjpeg-turbo/build-ios/Debug"
        -add_rpath "/opt/libjpeg-turbo/lib"
        "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/bin/djpeg")
      if(CMAKE_INSTALL_DO_STRIP)
        execute_process(COMMAND "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/strip" -u -r "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/bin/djpeg")
      endif()
    endif()
  elseif(CMAKE_INSTALL_CONFIG_NAME MATCHES "^([Rr][Ee][Ll][Ee][Aa][Ss][Ee])$")
    file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/bin" TYPE EXECUTABLE FILES "/Users/argenzhukeev/projects/imagekit_ffi/third_party/libjpeg-turbo/build-ios/Release/djpeg")
    if(EXISTS "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/bin/djpeg" AND
       NOT IS_SYMLINK "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/bin/djpeg")
      execute_process(COMMAND /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/install_name_tool
        -delete_rpath "/Users/argenzhukeev/projects/imagekit_ffi/third_party/libjpeg-turbo/build-ios/Release"
        -add_rpath "/opt/libjpeg-turbo/lib"
        "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/bin/djpeg")
      if(CMAKE_INSTALL_DO_STRIP)
        execute_process(COMMAND "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/strip" -u -r "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/bin/djpeg")
      endif()
    endif()
  elseif(CMAKE_INSTALL_CONFIG_NAME MATCHES "^([Mm][Ii][Nn][Ss][Ii][Zz][Ee][Rr][Ee][Ll])$")
    file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/bin" TYPE EXECUTABLE FILES "/Users/argenzhukeev/projects/imagekit_ffi/third_party/libjpeg-turbo/build-ios/MinSizeRel/djpeg")
    if(EXISTS "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/bin/djpeg" AND
       NOT IS_SYMLINK "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/bin/djpeg")
      execute_process(COMMAND /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/install_name_tool
        -delete_rpath "/Users/argenzhukeev/projects/imagekit_ffi/third_party/libjpeg-turbo/build-ios/MinSizeRel"
        -add_rpath "/opt/libjpeg-turbo/lib"
        "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/bin/djpeg")
      if(CMAKE_INSTALL_DO_STRIP)
        execute_process(COMMAND "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/strip" -u -r "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/bin/djpeg")
      endif()
    endif()
  elseif(CMAKE_INSTALL_CONFIG_NAME MATCHES "^([Rr][Ee][Ll][Ww][Ii][Tt][Hh][Dd][Ee][Bb][Ii][Nn][Ff][Oo])$")
    file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/bin" TYPE EXECUTABLE FILES "/Users/argenzhukeev/projects/imagekit_ffi/third_party/libjpeg-turbo/build-ios/RelWithDebInfo/djpeg")
    if(EXISTS "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/bin/djpeg" AND
       NOT IS_SYMLINK "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/bin/djpeg")
      execute_process(COMMAND /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/install_name_tool
        -delete_rpath "/Users/argenzhukeev/projects/imagekit_ffi/third_party/libjpeg-turbo/build-ios/RelWithDebInfo"
        -add_rpath "/opt/libjpeg-turbo/lib"
        "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/bin/djpeg")
      if(CMAKE_INSTALL_DO_STRIP)
        execute_process(COMMAND "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/strip" -u -r "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/bin/djpeg")
      endif()
    endif()
  endif()
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "bin" OR NOT CMAKE_INSTALL_COMPONENT)
  if(CMAKE_INSTALL_CONFIG_NAME MATCHES "^([Dd][Ee][Bb][Uu][Gg])$")
    file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/bin" TYPE EXECUTABLE FILES "/Users/argenzhukeev/projects/imagekit_ffi/third_party/libjpeg-turbo/build-ios/Debug/jpegtran")
    if(EXISTS "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/bin/jpegtran" AND
       NOT IS_SYMLINK "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/bin/jpegtran")
      execute_process(COMMAND /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/install_name_tool
        -delete_rpath "/Users/argenzhukeev/projects/imagekit_ffi/third_party/libjpeg-turbo/build-ios/Debug"
        -add_rpath "/opt/libjpeg-turbo/lib"
        "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/bin/jpegtran")
      if(CMAKE_INSTALL_DO_STRIP)
        execute_process(COMMAND "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/strip" -u -r "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/bin/jpegtran")
      endif()
    endif()
  elseif(CMAKE_INSTALL_CONFIG_NAME MATCHES "^([Rr][Ee][Ll][Ee][Aa][Ss][Ee])$")
    file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/bin" TYPE EXECUTABLE FILES "/Users/argenzhukeev/projects/imagekit_ffi/third_party/libjpeg-turbo/build-ios/Release/jpegtran")
    if(EXISTS "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/bin/jpegtran" AND
       NOT IS_SYMLINK "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/bin/jpegtran")
      execute_process(COMMAND /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/install_name_tool
        -delete_rpath "/Users/argenzhukeev/projects/imagekit_ffi/third_party/libjpeg-turbo/build-ios/Release"
        -add_rpath "/opt/libjpeg-turbo/lib"
        "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/bin/jpegtran")
      if(CMAKE_INSTALL_DO_STRIP)
        execute_process(COMMAND "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/strip" -u -r "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/bin/jpegtran")
      endif()
    endif()
  elseif(CMAKE_INSTALL_CONFIG_NAME MATCHES "^([Mm][Ii][Nn][Ss][Ii][Zz][Ee][Rr][Ee][Ll])$")
    file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/bin" TYPE EXECUTABLE FILES "/Users/argenzhukeev/projects/imagekit_ffi/third_party/libjpeg-turbo/build-ios/MinSizeRel/jpegtran")
    if(EXISTS "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/bin/jpegtran" AND
       NOT IS_SYMLINK "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/bin/jpegtran")
      execute_process(COMMAND /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/install_name_tool
        -delete_rpath "/Users/argenzhukeev/projects/imagekit_ffi/third_party/libjpeg-turbo/build-ios/MinSizeRel"
        -add_rpath "/opt/libjpeg-turbo/lib"
        "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/bin/jpegtran")
      if(CMAKE_INSTALL_DO_STRIP)
        execute_process(COMMAND "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/strip" -u -r "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/bin/jpegtran")
      endif()
    endif()
  elseif(CMAKE_INSTALL_CONFIG_NAME MATCHES "^([Rr][Ee][Ll][Ww][Ii][Tt][Hh][Dd][Ee][Bb][Ii][Nn][Ff][Oo])$")
    file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/bin" TYPE EXECUTABLE FILES "/Users/argenzhukeev/projects/imagekit_ffi/third_party/libjpeg-turbo/build-ios/RelWithDebInfo/jpegtran")
    if(EXISTS "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/bin/jpegtran" AND
       NOT IS_SYMLINK "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/bin/jpegtran")
      execute_process(COMMAND /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/install_name_tool
        -delete_rpath "/Users/argenzhukeev/projects/imagekit_ffi/third_party/libjpeg-turbo/build-ios/RelWithDebInfo"
        -add_rpath "/opt/libjpeg-turbo/lib"
        "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/bin/jpegtran")
      if(CMAKE_INSTALL_DO_STRIP)
        execute_process(COMMAND "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/strip" -u -r "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/bin/jpegtran")
      endif()
    endif()
  endif()
endif()

