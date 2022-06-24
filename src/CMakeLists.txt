# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.10)

project(warp_dart_library VERSION 0.0.1 LANGUAGES C)

add_library(warp_dart SHARED
  "warp_dart.c"
)

set_target_properties(warp_dart PROPERTIES
  PUBLIC_HEADER warp_dart.h
  OUTPUT_NAME "warp_dart"
)

target_compile_definitions(warp_dart PUBLIC DART_SHARED_LIB)
