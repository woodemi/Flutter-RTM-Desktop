cmake_minimum_required(VERSION 3.15)
set(PROJECT_NAME "agora_rtm")
project(${PROJECT_NAME} LANGUAGES CXX)

set(PLUGIN_NAME "${PROJECT_NAME}_plugin")

add_library(${PLUGIN_NAME} SHARED
  "${PLUGIN_NAME}.cpp"
  "RTMChannel.cpp"
  "RTMClient.cpp"
)
apply_standard_settings(${PLUGIN_NAME})
set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden)
target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)
target_include_directories(${PLUGIN_NAME}
  INTERFACE "${CMAKE_CURRENT_SOURCE_DIR}/include"
  PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/sdk/include")
find_library(AGORA_RTM_LIB agora_rtm_sdk "${CMAKE_CURRENT_SOURCE_DIR}/sdk/lib")
target_link_libraries(${PLUGIN_NAME} PRIVATE flutter flutter_wrapper_plugin ${AGORA_RTM_LIB})

# List of absolute paths to libraries that should be bundled with the plugin
set(agora_rtm_bundled_libraries
  "${CMAKE_CURRENT_SOURCE_DIR}/sdk/dll/agora_rtm_sdk.dll"
  PARENT_SCOPE
)
