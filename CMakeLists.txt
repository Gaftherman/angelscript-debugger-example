cmake_minimum_required(VERSION 3.21)
project(AngelScriptDebugExample LANGUAGES CXX)

set(ASDEBUGGER_DIR "${CMAKE_CURRENT_SOURCE_DIR}/external/angelscript-dap"
    CACHE PATH "Checkout of angelscript-dap, the host-agnostic debugger core")
set(ANGELSCRIPT_SDK "${CMAKE_CURRENT_SOURCE_DIR}/external/angelscript/sdk"
    CACHE PATH "AngelScript sdk directory")

if(NOT EXISTS "${ANGELSCRIPT_SDK}/angelscript/projects/cmake/CMakeLists.txt")
    message(FATAL_ERROR "Initialize AngelScript with git submodule update --init --recursive.")
endif()
if(NOT EXISTS "${ASDEBUGGER_DIR}/src/as_debugger_host.h")
    message(FATAL_ERROR "angelscript-dap is missing at ${ASDEBUGGER_DIR}. Run git submodule update --init.")
endif()

set(CMAKE_POLICY_DEFAULT_CMP0077 NEW)
set(BUILD_SHARED_LIBS OFF)
set(AS_DISABLE_INSTALL ON)
add_subdirectory("${ANGELSCRIPT_SDK}/angelscript/projects/cmake" angelscript)

if(NOT DEFINED ASDEBUGGER_BUILD_TESTS)
    set(ASDEBUGGER_BUILD_TESTS OFF)
endif()
set(ASDEBUGGER_STD_ADAPTER ON)
set(ASDEBUGGER_STD_ADDON_DIR "${ANGELSCRIPT_SDK}/add_on")
add_subdirectory("${ASDEBUGGER_DIR}" asdebugger)
enable_testing()

add_executable(angelscript-demo host/main.cpp)
set_target_properties(angelscript-demo PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin")
target_compile_features(angelscript-demo PRIVATE cxx_std_20)
foreach(addon IN ITEMS scriptstdstring scriptarray scriptdictionary scriptmath scriptbuilder scripthelper)
    set(addon_dir "${ASDEBUGGER_STD_ADDON_DIR}/${addon}")
    target_sources(angelscript-demo PRIVATE "${addon_dir}/${addon}.cpp")
    target_include_directories(angelscript-demo PRIVATE "${addon_dir}")
endforeach()
target_link_libraries(angelscript-demo PRIVATE asdebugger_core)
