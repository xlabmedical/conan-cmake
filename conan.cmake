# The MIT License (MIT)

# Copyright (c) 2018 JFrog

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.



# This file comes from: https://github.com/conan-io/cmake-conan. Please refer
# to this repository for issues and documentation.

# Its purpose is to wrap and launch Conan C/C++ Package Manager when cmake is called.
# It will take CMake current settings (os, compiler, compiler version, architecture)
# and translate them to conan settings for installing and retrieving dependencies.

# It is intended to facilitate developers building projects that have conan dependencies,
# but it is only necessary on the end-user side. It is not necessary to create conan
# packages, in fact it shouldn't be use for that. Check the project documentation.

# version: 0.19.0-dev

include(CMakeParseArguments)


# Detect 'compiler.version' setting for 'Visual Studio', 
# which will be deprecated in Conan 2.0.
function(_conan_detect_vs_version result)
    set(${result} "" PARENT_SCOPE)
    if(NOT MSVC_VERSION VERSION_LESS 1400 AND MSVC_VERSION VERSION_LESS 1500)
        # VS2005, VC 8.0
        set(${result} 8 PARENT_SCOPE)
    elseif(NOT MSVC_VERSION VERSION_LESS 1500 AND MSVC_VERSION VERSION_LESS 1600)
        # VS2008, VC 9.0
        set(${result} 9 PARENT_SCOPE)
    elseif(NOT MSVC_VERSION VERSION_LESS 1600 AND MSVC_VERSION VERSION_LESS 1700)
        # VS2010, VC 10.0
        set(${result} 10 PARENT_SCOPE)
    elseif(NOT MSVC_VERSION VERSION_LESS 1700 AND MSVC_VERSION VERSION_LESS 1800)
        # VS2012, VC 11.0
        set(${result} 11 PARENT_SCOPE)
    elseif(NOT MSVC_VERSION VERSION_LESS 1800 AND MSVC_VERSION VERSION_LESS 1900)
        # VS2013, VC 12.0
        set(${result} 12 PARENT_SCOPE)
    elseif(NOT MSVC_VERSION VERSION_LESS 1900 AND MSVC_VERSION VERSION_LESS 1910)
        # VS2015, VC 14.0
        set(${result} 14 PARENT_SCOPE)
    elseif(NOT MSVC_VERSION VERSION_LESS 1910 AND MSVC_VERSION VERSION_LESS 1920)
        # VS2017, VC 15.0
        set(${result} 15 PARENT_SCOPE)
    elseif(NOT MSVC_VERSION VERSION_LESS 1920 AND MSVC_VERSION VERSION_LESS 1930)
        # VS2019, VC 16.0
        set(${result} 16 PARENT_SCOPE)
    elseif(NOT MSVC_VERSION VERSION_LESS 1930 AND MSVC_VERSION VERSION_LESS 1940)
        # VS2022, VC 17.0
        set(${result} 17 PARENT_SCOPE)
    else()
        message(FATAL_ERROR "Conan: Unknown MSVC compiler version [${MSVC_VERSION}]")
    endif()
endfunction()


# Detect 'compiler.runtime' setting for 'Visual Studio',
# which will be deprecated in Conan 2.0.
function(_conan_detect_vs_runtime result)
    conan_parse_arguments(${ARGV})
    if(ARGUMENTS_BUILD_TYPE)
        set(build_type "${ARGUMENTS_BUILD_TYPE}")
    elseif(CMAKE_BUILD_TYPE)
        set(build_type "${CMAKE_BUILD_TYPE}")
    else()
        message(FATAL_ERROR "Please specify in command line CMAKE_BUILD_TYPE (-DCMAKE_BUILD_TYPE=Release)")
    endif()

    if(build_type)
        string(TOUPPER "${build_type}" build_type)
    endif()
    set(variables CMAKE_CXX_FLAGS_${build_type} CMAKE_C_FLAGS_${build_type} CMAKE_CXX_FLAGS CMAKE_C_FLAGS)
    foreach(variable ${variables})
        if(NOT "${${variable}}" STREQUAL "")
            string(REPLACE " " ";" flags "${${variable}}")
            foreach (flag ${flags})
                if("${flag}" STREQUAL "/MD" OR "${flag}" STREQUAL "/MDd" OR "${flag}" STREQUAL "/MT" OR "${flag}" STREQUAL "/MTd")
                    string(SUBSTRING "${flag}" 1 -1 runtime)
                    set(${result} "${runtime}" PARENT_SCOPE)
                    return()
                endif()
            endforeach()
        endif()
    endforeach()
    if("${build_type}" STREQUAL "DEBUG")
        set(${result} "MDd" PARENT_SCOPE)
    else()
        set(${result} "MD" PARENT_SCOPE)
    endif()
endfunction()


# Detect 'compiler.version' setting for 'msvc'.
function(_conan_detect_msvc_version result_major result_minor)
    string(REGEX MATCH "..." MSVC_MAJOR "${MSVC_VERSION}")
    string(REGEX MATCH ".$" MSVC_MINOR "${MSVC_VERSION}")

    set(${result_major} ${MSVC_MAJOR} PARENT_SCOPE)
    set(${result_minor} ${MSVC_MINOR} PARENT_SCOPE)
endfunction()


# Detect 'compiler.runtime' and 'compiler.runtime_type' settings for 'msvc'.
function(_conan_detect_msvc_runtime result1 result2)

    conan_parse_arguments(${ARGV})
    if(ARGUMENTS_BUILD_TYPE)
        set(build_type "${ARGUMENTS_BUILD_TYPE}")
    elseif(CMAKE_BUILD_TYPE)
        set(build_type "${CMAKE_BUILD_TYPE}")
    else()
        message(FATAL_ERROR "Please specify in command line CMAKE_BUILD_TYPE (-DCMAKE_BUILD_TYPE=Release)")
    endif()

    if(build_type)
        string(TOUPPER "${build_type}" build_type)
    endif()
    set(variables CMAKE_CXX_FLAGS_${build_type} CMAKE_C_FLAGS_${build_type} CMAKE_CXX_FLAGS CMAKE_C_FLAGS)
    foreach(variable ${variables})
        if(NOT "${${variable}}" STREQUAL "")
            string(REPLACE " " ";" flags "${${variable}}")
            foreach (flag ${flags})
                if("${flag}" STREQUAL "/MD")
                    set(${result1} "dynamic" PARENT_SCOPE)
                    set(${result2} "Release" PARENT_SCOPE)
                    return()
                elseif("${flag}" STREQUAL "/MDd")
                    set(${result1} "dynamic" PARENT_SCOPE)
                    set(${result2} "Debug" PARENT_SCOPE)
                    return()
                elseif("${flag}" STREQUAL "/MT")
                    set(${result1} "static" PARENT_SCOPE)
                    set(${result2} "Release" PARENT_SCOPE)
                    return()
                elseif("${flag}" STREQUAL "/MTd")
                    set(${result1} "static" PARENT_SCOPE)
                    set(${result2} "Debug" PARENT_SCOPE)
                    return()
                endif()
            endforeach()
        endif()
    endforeach()
    if("${build_type}" STREQUAL "DEBUG")
        # /MDd
        set(${result1} "dynamic" PARENT_SCOPE)
        set(${result2} "Debug" PARENT_SCOPE)
    else()
        # /MD
        set(${result1} "dynamic" PARENT_SCOPE)
        set(${result2} "Release" PARENT_SCOPE)
    endif()
endfunction()


# Detect 'compiler.libcxx' setting for 'gcc', 'clang'...etc.
function(_conan_detect_unix_libcxx result)
    # Take into account any -stdlib in compile options
    get_directory_property(compile_options DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} COMPILE_OPTIONS)
    string(GENEX_STRIP "${compile_options}" compile_options)

    # Take into account any _GLIBCXX_USE_CXX11_ABI in compile definitions
    get_directory_property(defines DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} COMPILE_DEFINITIONS)
    string(GENEX_STRIP "${defines}" defines)

    foreach(define ${defines})
        if(define MATCHES "_GLIBCXX_USE_CXX11_ABI")
            if(define MATCHES "^-D")
                set(compile_options ${compile_options} "${define}")
            else()
                set(compile_options ${compile_options} "-D${define}")
            endif()
        endif()
    endforeach()

    # add additional compiler options ala cmRulePlaceholderExpander::ExpandRuleVariable
    set(EXPAND_CXX_COMPILER ${CMAKE_CXX_COMPILER})
    if(CMAKE_CXX_COMPILER_ARG1)
        # CMake splits CXX="foo bar baz" into CMAKE_CXX_COMPILER="foo", CMAKE_CXX_COMPILER_ARG1="bar baz"
        # without this, ccache, winegcc, or other wrappers might lose all their arguments
        separate_arguments(SPLIT_CXX_COMPILER_ARG1 NATIVE_COMMAND ${CMAKE_CXX_COMPILER_ARG1})
        list(APPEND EXPAND_CXX_COMPILER ${SPLIT_CXX_COMPILER_ARG1})
    endif()

    if(CMAKE_CXX_COMPILE_OPTIONS_TARGET AND CMAKE_CXX_COMPILER_TARGET)
        # without --target= we may be calling the wrong underlying GCC
        list(APPEND EXPAND_CXX_COMPILER "${CMAKE_CXX_COMPILE_OPTIONS_TARGET}${CMAKE_CXX_COMPILER_TARGET}")
    endif()

    if(CMAKE_CXX_COMPILE_OPTIONS_EXTERNAL_TOOLCHAIN AND CMAKE_CXX_COMPILER_EXTERNAL_TOOLCHAIN)
        list(APPEND EXPAND_CXX_COMPILER "${CMAKE_CXX_COMPILE_OPTIONS_EXTERNAL_TOOLCHAIN}${CMAKE_CXX_COMPILER_EXTERNAL_TOOLCHAIN}")
    endif()

    if(CMAKE_CXX_COMPILE_OPTIONS_SYSROOT)
        # without --sysroot= we may find the wrong #include <string>
        if(CMAKE_SYSROOT_COMPILE)
            list(APPEND EXPAND_CXX_COMPILER "${CMAKE_CXX_COMPILE_OPTIONS_SYSROOT}${CMAKE_SYSROOT_COMPILE}")
        elseif(CMAKE_SYSROOT)
            list(APPEND EXPAND_CXX_COMPILER "${CMAKE_CXX_COMPILE_OPTIONS_SYSROOT}${CMAKE_SYSROOT}")
        endif()
    endif()

    separate_arguments(SPLIT_CXX_FLAGS NATIVE_COMMAND ${CMAKE_CXX_FLAGS})

    if(CMAKE_OSX_SYSROOT)
        set(xcode_sysroot_option "--sysroot=${CMAKE_OSX_SYSROOT}")
    endif()

    execute_process(
        COMMAND ${CMAKE_COMMAND} -E echo "#include <string>"
        COMMAND ${EXPAND_CXX_COMPILER} ${SPLIT_CXX_FLAGS} -x c++ ${xcode_sysroot_option} ${compile_options} -E -dM -
        OUTPUT_VARIABLE string_defines
    )

    if(string_defines MATCHES "#define __GLIBCXX__")
        # Allow -D_GLIBCXX_USE_CXX11_ABI=ON/OFF as argument to cmake
        if(DEFINED _GLIBCXX_USE_CXX11_ABI)
            if(_GLIBCXX_USE_CXX11_ABI)
                set(${result} libstdc++11 PARENT_SCOPE)
                return()
            else()
                set(${result} libstdc++ PARENT_SCOPE)
                return()
            endif()
        endif()

        if(string_defines MATCHES "#define _GLIBCXX_USE_CXX11_ABI 1\n")
            set(${result} libstdc++11 PARENT_SCOPE)
        else()
            # Either the compiler is missing the define because it is old, and so
            # it can't use the new abi, or the compiler was configured to use the
            # old abi by the user or distro (e.g. devtoolset on RHEL/CentOS)
            set(${result} libstdc++ PARENT_SCOPE)
        endif()
    else()
        set(${result} libc++ PARENT_SCOPE)
    endif()
endfunction()


# Detect 'build_type' setting.
macro(_conan_detect_build_type)
    conan_parse_arguments(${ARGV})

    if(ARGUMENTS_BUILD_TYPE)
        set(_CONAN_SETTING_BUILD_TYPE ${ARGUMENTS_BUILD_TYPE})
    elseif(CMAKE_BUILD_TYPE)
        set(_CONAN_SETTING_BUILD_TYPE ${CMAKE_BUILD_TYPE})
    else()
        message(FATAL_ERROR "Please specify in command line CMAKE_BUILD_TYPE (-DCMAKE_BUILD_TYPE=Release)")
    endif()

    string(TOUPPER ${_CONAN_SETTING_BUILD_TYPE} _CONAN_SETTING_BUILD_TYPE_UPPER)
    if (_CONAN_SETTING_BUILD_TYPE_UPPER STREQUAL "DEBUG")
        set(_CONAN_SETTING_BUILD_TYPE "Debug")
    elseif(_CONAN_SETTING_BUILD_TYPE_UPPER STREQUAL "RELEASE")
        set(_CONAN_SETTING_BUILD_TYPE "Release")
    elseif(_CONAN_SETTING_BUILD_TYPE_UPPER STREQUAL "RELWITHDEBINFO")
        set(_CONAN_SETTING_BUILD_TYPE "RelWithDebInfo")
    elseif(_CONAN_SETTING_BUILD_TYPE_UPPER STREQUAL "MINSIZEREL")
        set(_CONAN_SETTING_BUILD_TYPE "MinSizeRel")
    endif()
endmacro()


# Detect 'arch' setting.
macro(_conan_detect_arch)
    conan_parse_arguments(${ARGV})
    if (ARGUMENTS_ARCH)
        set(_CONAN_SETTING_ARCH ${ARGUMENTS_ARCH})
    else ()
        if ("${CMAKE_${LANGUAGE}_COMPILER_ID}" STREQUAL "MSVC" 
            OR ("${CMAKE_${LANGUAGE}_COMPILER_ID}" STREQUAL "Clang" 
                AND "${CMAKE_${LANGUAGE}_SIMULATE_ID}" STREQUAL "MSVC"))
            # Available for MSVC 
            # Available for MSVC-based Clang
            if (CMAKE_${LANGUAGE}_COMPILER_ARCHITECTURE_ID MATCHES "64")
                set(_CONAN_SETTING_ARCH x86_64)
            elseif (CMAKE_${LANGUAGE}_COMPILER_ARCHITECTURE_ID MATCHES "^ARM")
                set(_CONAN_SETTING_ARCH armv6)
            elseif (CMAKE_${LANGUAGE}_COMPILER_ARCHITECTURE_ID MATCHES "86")
                set(_CONAN_SETTING_ARCH x86)
            else ()
                # Other architectures...
            endif()
        else ()
            # Other C/C++ compilers...
            # Use other mechanism to detect its architecture 
        endif ()
    endif ()
endmacro ()


# Detect 'os' setting.
macro(_conan_check_system_name)
    #handle -s os setting
    if(CMAKE_SYSTEM_NAME AND NOT CMAKE_SYSTEM_NAME STREQUAL "Generic")
        #use default conan os setting if CMAKE_SYSTEM_NAME is not defined
        set(CONAN_SYSTEM_NAME ${CMAKE_SYSTEM_NAME})
        if(${CMAKE_SYSTEM_NAME} STREQUAL "Darwin")
            set(CONAN_SYSTEM_NAME Macos)
        endif()
        if(${CMAKE_SYSTEM_NAME} STREQUAL "QNX")
            set(CONAN_SYSTEM_NAME Neutrino)
        endif()
        set(CONAN_SUPPORTED_PLATFORMS Windows Linux Macos Android iOS FreeBSD WindowsStore WindowsCE watchOS tvOS FreeBSD SunOS AIX Arduino Emscripten Neutrino)
        list (FIND CONAN_SUPPORTED_PLATFORMS "${CONAN_SYSTEM_NAME}" _index)
        if (${_index} GREATER -1)
            #check if the cmake system is a conan supported one
            set(_CONAN_SETTING_OS ${CONAN_SYSTEM_NAME})
        else()
            message(FATAL_ERROR "cmake system ${CONAN_SYSTEM_NAME} is not supported by conan. Use one of ${CONAN_SUPPORTED_PLATFORMS}")
        endif()
    endif()
endmacro()

macro(_conan_check_language)
    get_property(_languages GLOBAL PROPERTY ENABLED_LANGUAGES)
    if (";${_languages};" MATCHES ";CXX;")
        set(LANGUAGE CXX)
        set(USING_CXX 1)
    elseif (";${_languages};" MATCHES ";C;")
        set(LANGUAGE C)
        set(USING_CXX 0)
    else ()
        message(FATAL_ERROR "Conan: Neither C or C++ was detected as a language for the project. Unabled to detect compiler version.")
    endif()
endmacro()

macro(_conan_detect_compiler)

    conan_parse_arguments(${ARGV})

    if(ARGUMENTS_ARCH)
        set(_CONAN_SETTING_ARCH ${ARGUMENTS_ARCH})
    endif()

    if(USING_CXX)
        set(_CONAN_SETTING_COMPILER_CPPSTD ${CMAKE_CXX_STANDARD})
    endif()

    if (${CMAKE_${LANGUAGE}_COMPILER_ID} STREQUAL GNU OR ${CMAKE_${LANGUAGE}_COMPILER_ID} STREQUAL QCC)
        # using GCC or QCC
        # TODO: Handle other params
        string(REPLACE "." ";" VERSION_LIST ${CMAKE_${LANGUAGE}_COMPILER_VERSION})
        list(GET VERSION_LIST 0 MAJOR)
        list(GET VERSION_LIST 1 MINOR)

        if (${CMAKE_${LANGUAGE}_COMPILER_ID} STREQUAL GNU)
            set(_CONAN_SETTING_COMPILER gcc)
            # mimic Conan client autodetection
            if (${MAJOR} GREATER_EQUAL 5)
                set(COMPILER_VERSION ${MAJOR})
            else()
                set(COMPILER_VERSION ${MAJOR}.${MINOR})
            endif()    
        elseif (${CMAKE_${LANGUAGE}_COMPILER_ID} STREQUAL QCC)
            set(_CONAN_SETTING_COMPILER qcc)
            set(COMPILER_VERSION ${MAJOR}.${MINOR})
        endif ()

        set(_CONAN_SETTING_COMPILER_VERSION ${COMPILER_VERSION})

        if (USING_CXX)
            _conan_detect_unix_libcxx(_LIBCXX)
            set(_CONAN_SETTING_COMPILER_LIBCXX ${_LIBCXX})
        endif ()
    elseif (${CMAKE_${LANGUAGE}_COMPILER_ID} STREQUAL Intel)
        string(REPLACE "." ";" VERSION_LIST ${CMAKE_${LANGUAGE}_COMPILER_VERSION})
        list(GET VERSION_LIST 0 MAJOR)
        list(GET VERSION_LIST 1 MINOR)
        set(COMPILER_VERSION ${MAJOR})
        set(_CONAN_SETTING_COMPILER intel)
        set(_CONAN_SETTING_COMPILER_VERSION ${COMPILER_VERSION})
        if (USING_CXX)
            _conan_detect_unix_libcxx(_LIBCXX)
            set(_CONAN_SETTING_COMPILER_LIBCXX ${_LIBCXX})
        endif ()
    elseif (${CMAKE_${LANGUAGE}_COMPILER_ID} STREQUAL AppleClang)
        # using AppleClang
        string(REPLACE "." ";" VERSION_LIST ${CMAKE_${LANGUAGE}_COMPILER_VERSION})
        list(GET VERSION_LIST 0 MAJOR)
        list(GET VERSION_LIST 1 MINOR)

        # mimic Conan client autodetection
        if (${MAJOR} GREATER_EQUAL 13)
            set(COMPILER_VERSION ${MAJOR})
        else()
            set(COMPILER_VERSION ${MAJOR}.${MINOR})
        endif() 

        set(_CONAN_SETTING_COMPILER_VERSION ${COMPILER_VERSION})

        set(_CONAN_SETTING_COMPILER apple-clang)
        if (USING_CXX)
            _conan_detect_unix_libcxx(_LIBCXX)
            set(_CONAN_SETTING_COMPILER_LIBCXX ${_LIBCXX})
        endif ()
    elseif (${CMAKE_${LANGUAGE}_COMPILER_ID} STREQUAL Clang
                AND NOT "${CMAKE_${LANGUAGE}_COMPILER_FRONTEND_VARIANT}" STREQUAL "MSVC" 
                AND NOT "${CMAKE_${LANGUAGE}_SIMULATE_ID}" STREQUAL "MSVC")

        string(REPLACE "." ";" VERSION_LIST ${CMAKE_${LANGUAGE}_COMPILER_VERSION})
        list(GET VERSION_LIST 0 MAJOR)
        list(GET VERSION_LIST 1 MINOR)
        set(_CONAN_SETTING_COMPILER clang)

        # mimic Conan client autodetection
        if (${MAJOR} GREATER_EQUAL 8)
            set(COMPILER_VERSION ${MAJOR})
        else()
            set(COMPILER_VERSION ${MAJOR}.${MINOR})
        endif() 

        set(_CONAN_SETTING_COMPILER_VERSION ${COMPILER_VERSION})

        if(APPLE)
            cmake_policy(GET CMP0025 APPLE_CLANG_POLICY)
            if(NOT APPLE_CLANG_POLICY STREQUAL NEW)
                message(STATUS "Conan: APPLE and Clang detected. Assuming apple-clang compiler. Set CMP0025 to avoid it")
                set(_CONAN_SETTING_COMPILER apple-clang)
            endif()
        endif()
        if (USING_CXX)
            _conan_detect_unix_libcxx(_LIBCXX)
            set(_CONAN_SETTING_COMPILER_LIBCXX ${_LIBCXX})
        endif ()
    elseif (MSVC)
        if(CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
            # Detect 'compiler' and 'compiler.version' settings.
            set(_MSVC_CLANG "clang")

            string(REPLACE "." ";" VERSION_LIST ${CMAKE_${LANGUAGE}_COMPILER_VERSION})
            list(GET VERSION_LIST 0 _MSVC_CLANG_VERSION_MAJOR)
            list(GET VERSION_LIST 1 _MSVC_CLANG_VERSION_MINOR)
            set(_CONAN_SETTING_COMPILER ${_MSVC_CLANG})
            set(_CONAN_SETTING_COMPILER_VERSION ${_MSVC_CLANG_VERSION_MAJOR})
            set(_CONAN_SETTING_COMPILER_UPDATE ${_MSVC_CLANG_VERSION_MINOR})
        else()
            set(_MSVC "msvc")
            _conan_detect_msvc_version(_MSVC_VERSION_MAJOR _MSVC_VERSION_MINOR)
            set(_CONAN_SETTING_COMPILER ${_MSVC})
            set(_CONAN_SETTING_COMPILER_VERSION ${_MSVC_VERSION_MAJOR})
            set(_CONAN_SETTING_COMPILER_UPDATE ${_MSVC_VERSION_MINOR})
        endif()        

        # Detect 'compiler.runtime' and 'compiler.runtime_type' settings.
        _conan_detect_msvc_runtime(_MSVC_RUNTIME _MSVC_RUNTIME_TYPE ${ARGV})
        message(STATUS "Conan: Detected MSVC runtime: ${_MSVC_RUNTIME}")
        set(_CONAN_SETTING_COMPILER_RUNTIME ${_MSVC_RUNTIME})
        message(STATUS "Conan: Detected MSVC runtime_type: ${_MSVC_RUNTIME_TYPE}")
        set(_CONAN_SETTING_COMPILER_RUNTIME_TYPE ${_MSVC_RUNTIME_TYPE})

        # Detect 'compiler.toolset' setting.
        set(_XP_TOOLSETS v110_xp v120_xp v140_xp v141_xp)
        foreach(_XP_TOOLSET ${_XP_TOOLSETS})
            if (CMAKE_GENERATOR_TOOLSET MATCHES ${_XP_TOOLSET})
                if (CMAKE_GENERATOR_TOOLSET)
                    set(_CONAN_SETTING_COMPILER_TOOLSET ${CMAKE_VS_PLATFORM_TOOLSET})
                elseif(CMAKE_VS_PLATFORM_TOOLSET AND (CMAKE_GENERATOR STREQUAL "Ninja"))
                    set(_CONAN_SETTING_COMPILER_TOOLSET ${CMAKE_VS_PLATFORM_TOOLSET})
                endif()
            endif()
        endforeach()

        # Detect 'compiler.cppstd' setting.
        if(CMAKE_CXX_STANDARD)
            set(_CONAN_SETTING_COMPILER_CPPSTD ${CMAKE_CXX_STANDARD})
        else()
            if(MSVC_VERSION VERSION_LESS 1900)
                # VS < 2015, specify C++98 standard by default.
                set(_CONAN_SETTING_COMPILER_CPPSTD 98)
            else()
                # VS >= 2015, specify C++14 standard by default.
                set(_CONAN_SETTING_COMPILER_CPPSTD 14)
            endif()
        endif()
    else()
        message(FATAL_ERROR "Conan: compiler setup not recognized")
    endif()

endmacro()

function(conan_cmake_settings result)
    #message(STATUS "COMPILER " ${CMAKE_CXX_COMPILER})
    #message(STATUS "COMPILER " ${CMAKE_CXX_COMPILER_ID})
    #message(STATUS "VERSION " ${CMAKE_CXX_COMPILER_VERSION})
    #message(STATUS "FLAGS " ${CMAKE_LANG_FLAGS})
    #message(STATUS "LIB ARCH " ${CMAKE_CXX_LIBRARY_ARCHITECTURE})
    #message(STATUS "BUILD TYPE " ${CMAKE_BUILD_TYPE})
    #message(STATUS "GENERATOR " ${CMAKE_GENERATOR})
    #message(STATUS "GENERATOR WIN64 " ${CMAKE_CL_64})

    message(STATUS "Conan: Automatic detection of conan settings from cmake")

    conan_parse_arguments(${ARGV})

    _conan_detect_build_type(${ARGV})
    _conan_detect_arch(${ARGV})
    _conan_check_system_name()
    _conan_check_language()
    _conan_detect_compiler(${ARGV})

    # If profile is defined it is used
    if(CMAKE_BUILD_TYPE STREQUAL "Debug" AND ARGUMENTS_DEBUG_PROFILE)
        set(_APPLIED_PROFILES ${ARGUMENTS_DEBUG_PROFILE})
    elseif(CMAKE_BUILD_TYPE STREQUAL "Release" AND ARGUMENTS_RELEASE_PROFILE)
        set(_APPLIED_PROFILES ${ARGUMENTS_RELEASE_PROFILE})
    elseif(CMAKE_BUILD_TYPE STREQUAL "RelWithDebInfo" AND ARGUMENTS_RELWITHDEBINFO_PROFILE)
        set(_APPLIED_PROFILES ${ARGUMENTS_RELWITHDEBINFO_PROFILE})
    elseif(CMAKE_BUILD_TYPE STREQUAL "MinSizeRel" AND ARGUMENTS_MINSIZEREL_PROFILE)
        set(_APPLIED_PROFILES ${ARGUMENTS_MINSIZEREL_PROFILE})
    elseif(ARGUMENTS_PROFILE)
        set(_APPLIED_PROFILES ${ARGUMENTS_PROFILE})
    endif()

    foreach(ARG ${_APPLIED_PROFILES})
        set(_SETTINGS ${_SETTINGS} -pr=${ARG})
    endforeach()
    foreach(ARG ${ARGUMENTS_PROFILE_BUILD})
        conan_check(VERSION 1.24.0 REQUIRED DETECT_QUIET)
        set(_SETTINGS ${_SETTINGS} -pr:b=${ARG})
    endforeach()

    if(NOT _SETTINGS OR ARGUMENTS_PROFILE_AUTO STREQUAL "ALL")
        set(ARGUMENTS_PROFILE_AUTO  arch build_type compiler compiler.version
                                    compiler.runtime compiler.runtime_type
                                    compiler.libcxx compiler.toolset
                                    compiler.cppstd compiler.update)
    endif()

    # remove any manually specified settings from the autodetected settings
    foreach(ARG ${ARGUMENTS_SETTINGS})
        string(REGEX MATCH "[^=]*" MANUAL_SETTING "${ARG}")
        message(STATUS "Conan: ${MANUAL_SETTING} was added as an argument. Not using the autodetected one.")
        list(REMOVE_ITEM ARGUMENTS_PROFILE_AUTO "${MANUAL_SETTING}")
    endforeach()

    # Automatic from CMake
    foreach(ARG ${ARGUMENTS_PROFILE_AUTO})
        string(TOUPPER ${ARG} _arg_name)
        string(REPLACE "." "_" _arg_name ${_arg_name})
        if(_CONAN_SETTING_${_arg_name})
            set(_SETTINGS ${_SETTINGS} -s ${ARG}=${_CONAN_SETTING_${_arg_name}})
        endif()
    endforeach()

    foreach(ARG ${ARGUMENTS_SETTINGS})
        set(_SETTINGS ${_SETTINGS} -s ${ARG})
    endforeach()

    message(STATUS "Conan: Settings= ${_SETTINGS}")

    set(${result} ${_SETTINGS} PARENT_SCOPE)
endfunction()


function(_collect_settings result)
    set(ARGUMENTS_PROFILE_AUTO  arch build_type compiler compiler.version compiler.update
                                compiler.runtime compiler.runtime_type 
                                compiler.libcxx compiler.toolset
                                compiler.cppstd compiler.update)
    foreach(ARG ${ARGUMENTS_PROFILE_AUTO})
        string(TOUPPER ${ARG} _arg_name)
        string(REPLACE "." "_" _arg_name ${_arg_name})
        if(_CONAN_SETTING_${_arg_name})
            set(detected_setings ${detected_setings} ${ARG}=${_CONAN_SETTING_${_arg_name}})
        endif()
    endforeach()
    set(${result} ${detected_setings} PARENT_SCOPE)
endfunction()

function(conan_cmake_autodetect detected_settings)
    # Detect whether CONAN_V2 is specified with ON:
    # - If CONAN_V2 is specified with ON, then MODE_CONAN_V2 will be ON.
    # - Otherwise:
    #   - If current Conan version is 1.0, then set MODE_CONAN_V2 to OFF.
    #   - If current Conan version is 2.0, then set MODE_CONAN_V2 TO ON.
    set(autodetectOneValueArgs CONAN_V2)
    cmake_parse_arguments(MODE "" "${autodetectOneValueArgs}" "" ${ARGV})
    set(MODE_CONAN_V2 ON)
    _conan_detect_build_type(${ARGV})
    _conan_detect_arch(${ARGV})
    _conan_check_system_name()
    _conan_check_language()
    _conan_detect_compiler(${ARGV})
    _collect_settings(collected_settings)
    set(${detected_settings} ${collected_settings} PARENT_SCOPE)
endfunction()

macro(conan_parse_arguments)
    set(options         BASIC_SETUP CMAKE_TARGETS UPDATE KEEP_RPATHS NO_LOAD NO_OUTPUT_DIRS 
                        OUTPUT_QUIET NO_IMPORTS SKIP_STD)
    set(oneValueArgs    CONANFILE ARCH BUILD_TYPE INSTALL_FOLDER OUTPUT_FOLDER CONAN_COMMAND)
    set(multiValueArgs  DEBUG_PROFILE RELEASE_PROFILE RELWITHDEBINFO_PROFILE MINSIZEREL_PROFILE
                        PROFILE REQUIRES OPTIONS IMPORTS SETTINGS BUILD ENV GENERATORS PROFILE_AUTO
                        INSTALL_ARGS CONFIGURATION_TYPES PROFILE_BUILD BUILD_REQUIRES)
    cmake_parse_arguments(ARGUMENTS "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})
endmacro()

function(old_conan_cmake_install)
    # Calls "conan install"
    # Argument BUILD is equivalent to --build={missing, PkgName,...} or
    # --build when argument is 'BUILD all' (which builds all packages from source)
    # Argument CONAN_COMMAND, to specify the conan path, e.g. in case of running from source
    # cmake does not identify conan as command, even if it is +x and it is in the path
    conan_parse_arguments(${ARGV})

    if(CONAN_CMAKE_MULTI)
        set(ARGUMENTS_GENERATORS ${ARGUMENTS_GENERATORS} cmake_multi)
    else()
        set(ARGUMENTS_GENERATORS ${ARGUMENTS_GENERATORS} cmake)
    endif()

    set(CONAN_BUILD_POLICY "")
    foreach(ARG ${ARGUMENTS_BUILD})
        if(${ARG} STREQUAL "all")
            set(CONAN_BUILD_POLICY ${CONAN_BUILD_POLICY} --build)
            break()
        else()
            set(CONAN_BUILD_POLICY ${CONAN_BUILD_POLICY} --build=${ARG})
        endif()
    endforeach()
    if(ARGUMENTS_CONAN_COMMAND)
       set(CONAN_CMD ${ARGUMENTS_CONAN_COMMAND})
    else()
        conan_check(REQUIRED)
    endif()
    set(CONAN_OPTIONS "")
    if(ARGUMENTS_CONANFILE)
      if(IS_ABSOLUTE ${ARGUMENTS_CONANFILE})
          set(CONANFILE ${ARGUMENTS_CONANFILE})
      else()
          set(CONANFILE ${CMAKE_CURRENT_SOURCE_DIR}/${ARGUMENTS_CONANFILE})
      endif()
    else()
      set(CONANFILE ".")
    endif()
    foreach(ARG ${ARGUMENTS_OPTIONS})
      set(CONAN_OPTIONS ${CONAN_OPTIONS} -o=${ARG})
    endforeach()
    if(ARGUMENTS_UPDATE)
      set(CONAN_INSTALL_UPDATE --update)
    endif()
    if(ARGUMENTS_NO_IMPORTS)
      set(CONAN_INSTALL_NO_IMPORTS --no-imports)
    endif()
    set(CONAN_INSTALL_FOLDER "")
    if(ARGUMENTS_INSTALL_FOLDER)
      set(CONAN_INSTALL_FOLDER -if=${ARGUMENTS_INSTALL_FOLDER})
    endif()
    set(CONAN_OUTPUT_FOLDER "")
    if(ARGUMENTS_OUTPUT_FOLDER)
      set(CONAN_OUTPUT_FOLDER -of=${ARGUMENTS_OUTPUT_FOLDER})
    endif()
    foreach(ARG ${ARGUMENTS_GENERATORS})
        set(CONAN_GENERATORS ${CONAN_GENERATORS} -g=${ARG})
    endforeach()
    foreach(ARG ${ARGUMENTS_ENV})
        set(CONAN_ENV_VARS ${CONAN_ENV_VARS} -e=${ARG})
    endforeach()
    set(conan_args install ${CONANFILE} ${settings} ${CONAN_ENV_VARS} ${CONAN_GENERATORS} ${CONAN_BUILD_POLICY} ${CONAN_INSTALL_UPDATE} ${CONAN_INSTALL_NO_IMPORTS} ${CONAN_OPTIONS} ${CONAN_INSTALL_FOLDER} ${ARGUMENTS_INSTALL_ARGS})

    string (REPLACE ";" " " _conan_args "${conan_args}")
    message(STATUS "Conan executing: ${CONAN_CMD} ${_conan_args}")

    if(ARGUMENTS_OUTPUT_QUIET)
        execute_process(COMMAND ${CONAN_CMD} ${conan_args}
                        RESULT_VARIABLE return_code
                        OUTPUT_VARIABLE conan_output
                        ERROR_VARIABLE conan_output
                        WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR})
    else()
        execute_process(COMMAND ${CONAN_CMD} ${conan_args}
                        RESULT_VARIABLE return_code
                        WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR})
    endif()

    if(NOT "${return_code}" STREQUAL "0")
      message(FATAL_ERROR "Conan install failed='${return_code}'")
    endif()

endfunction()

function(conan_cmake_install)
    if(DEFINED CONAN_COMMAND)
        set(CONAN_CMD ${CONAN_COMMAND})
    else()
        conan_check(REQUIRED)
    endif()

    set(installOptions UPDATE NO_IMPORTS OUTPUT_QUIET ERROR_QUIET)
    set(installOneValueArgs PATH_OR_REFERENCE REFERENCE REMOTE LOCKFILE LOCKFILE_OUT LOCKFILE_NODE_ID INSTALL_FOLDER OUTPUT_FOLDER)
    set(installMultiValueArgs GENERATOR BUILD ENV ENV_HOST ENV_BUILD OPTIONS_HOST OPTIONS OPTIONS_BUILD PROFILE
                              PROFILE_HOST PROFILE_BUILD SETTINGS SETTINGS_HOST SETTINGS_BUILD CONF CONF_HOST CONF_BUILD)
    cmake_parse_arguments(ARGS "${installOptions}" "${installOneValueArgs}" "${installMultiValueArgs}" ${ARGN})
    foreach(arg ${installOptions})
        if(ARGS_${arg})
            set(${arg} ${${arg}} ${ARGS_${arg}})
        endif()
    endforeach()
    foreach(arg ${installOneValueArgs})
        if(DEFINED ARGS_${arg})
            if("${arg}" STREQUAL "REMOTE")
                set(flag "--remote")
            elseif("${arg}" STREQUAL "LOCKFILE")
                set(flag "--lockfile")
            elseif("${arg}" STREQUAL "LOCKFILE_OUT")
                set(flag "--lockfile-out")
            elseif("${arg}" STREQUAL "LOCKFILE_NODE_ID")
                set(flag "--lockfile-node-id")
            elseif("${arg}" STREQUAL "INSTALL_FOLDER")
                set(flag "--install-folder")
            elseif("${arg}" STREQUAL "OUTPUT_FOLDER")
                set(flag "--output-folder")
            endif()
            set(${arg} ${${arg}} ${flag} ${ARGS_${arg}})
        endif()
    endforeach()
    foreach(arg ${installMultiValueArgs})
        if(DEFINED ARGS_${arg})
            if("${arg}" STREQUAL "GENERATOR")
                set(flag "--generator")
            elseif("${arg}" STREQUAL "BUILD")
                set(flag "--build")
            elseif("${arg}" STREQUAL "ENV")
                set(flag "--env")
            elseif("${arg}" STREQUAL "ENV_HOST")
                set(flag "--env:host")
            elseif("${arg}" STREQUAL "ENV_BUILD")
                set(flag "--env:build")
            elseif("${arg}" STREQUAL "OPTIONS")
                set(flag "--options")
            elseif("${arg}" STREQUAL "OPTIONS_HOST")
                set(flag "--options:host")
            elseif("${arg}" STREQUAL "OPTIONS_BUILD")
                set(flag "--options:build")
            elseif("${arg}" STREQUAL "PROFILE")
                set(flag "--profile")
            elseif("${arg}" STREQUAL "PROFILE_HOST")
                set(flag "--profile:host")
            elseif("${arg}" STREQUAL "PROFILE_BUILD")
                set(flag "--profile:build")
            elseif("${arg}" STREQUAL "SETTINGS")
                set(flag "--settings")
            elseif("${arg}" STREQUAL "SETTINGS_HOST")
                set(flag "--settings:host")
            elseif("${arg}" STREQUAL "SETTINGS_BUILD")
                set(flag "--settings:build")
            elseif("${arg}" STREQUAL "CONF")
                set(flag "--conf")
            elseif("${arg}" STREQUAL "CONF_HOST")
                set(flag "--conf:host")
            elseif("${arg}" STREQUAL "CONF_BUILD")
                set(flag "--conf:build")
            endif()
            list(LENGTH ARGS_${arg} numargs)
            foreach(item ${ARGS_${arg}})
                if(${item} STREQUAL "all" AND ${arg} STREQUAL "BUILD")
                    set(${arg} "--build")
                    break()
                endif()
                set(${arg} ${${arg}} ${flag} ${item})
            endforeach()
        endif()
    endforeach()
    if(DEFINED UPDATE)
        set(UPDATE --update)
    endif()
    if(DEFINED NO_IMPORTS)
        set(NO_IMPORTS --no-imports)
    endif()
    set(install_args install  ${PATH_OR_REFERENCE} ${REFERENCE} ${UPDATE} ${NO_IMPORTS} ${REMOTE} 
                              ${LOCKFILE} ${LOCKFILE_OUT} ${LOCKFILE_NODE_ID} ${INSTALL_FOLDER} 
                              ${OUTPUT_FOLDER} ${GENERATOR} ${BUILD} ${ENV} ${ENV_HOST} ${ENV_BUILD} 
                              ${OPTIONS} ${OPTIONS_HOST} ${OPTIONS_BUILD} ${PROFILE} ${PROFILE_HOST} 
                              ${PROFILE_BUILD} ${SETTINGS} ${SETTINGS_HOST} ${SETTINGS_BUILD} 
                              ${CONF} ${CONF_HOST} ${CONF_BUILD})

    string(REPLACE ";" " " _install_args "${install_args}")
    message(STATUS "Conan executing: ${CONAN_CMD} ${_install_args}")

    if(ARGS_OUTPUT_QUIET)
      set(OUTPUT_OPT OUTPUT_QUIET)
    endif()
    if(ARGS_ERROR_QUIET)
      set(ERROR_OPT ERROR_QUIET)
    endif()

    execute_process(COMMAND ${CONAN_CMD} ${install_args}
                    RESULT_VARIABLE return_code
                    ${OUTPUT_OPT}
                    ${ERROR_OPT}
                    WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR})

    if(NOT "${return_code}" STREQUAL "0")
        if (ARGS_ERROR_QUIET)
            message(WARNING "Conan install failed='${return_code}'")
        else()
            message(FATAL_ERROR "Conan install failed='${return_code}'")
        endif()
    endif()

endfunction()

function(conan_cmake_lock_create)
    if(DEFINED CONAN_COMMAND)
        set(CONAN_CMD ${CONAN_COMMAND})
    else()
        conan_check(REQUIRED)
    endif()

    set(lockCreateOptions UPDATE BASE OUTPUT_QUIET ERROR_QUIET)
    set(lockCreateOneValueArgs PATH REFERENCE REMOTE LOCKFILE LOCKFILE_OUT)
    set(lockCreateMultiValueArgs BUILD ENV ENV_HOST ENV_BUILD OPTIONS_HOST OPTIONS OPTIONS_BUILD PROFILE
                              PROFILE_HOST PROFILE_BUILD SETTINGS SETTINGS_HOST SETTINGS_BUILD)
    cmake_parse_arguments(ARGS "${lockCreateOptions}" "${lockCreateOneValueArgs}" "${lockCreateMultiValueArgs}" ${ARGN})
    foreach(arg ${lockCreateOptions})
        if(ARGS_${arg})
            set(${arg} ${${arg}} ${ARGS_${arg}})
        endif()
    endforeach()
    foreach(arg ${lockCreateOneValueArgs})
        if(DEFINED ARGS_${arg})
            if("${arg}" STREQUAL "REMOTE")
                set(flag "--remote")
            elseif("${arg}" STREQUAL "LOCKFILE")
                set(flag "--lockfile")
            elseif("${arg}" STREQUAL "LOCKFILE_OUT")
                set(flag "--lockfile-out")
            endif()
            set(${arg} ${${arg}} ${flag} ${ARGS_${arg}})
        endif()
    endforeach()
    foreach(arg ${lockCreateMultiValueArgs})
        if(DEFINED ARGS_${arg})
            if("${arg}" STREQUAL "BUILD")
                set(flag "--build")
            elseif("${arg}" STREQUAL "ENV")
                set(flag "--env")
            elseif("${arg}" STREQUAL "ENV_HOST")
                set(flag "--env:host")
            elseif("${arg}" STREQUAL "ENV_BUILD")
                set(flag "--env:build")
            elseif("${arg}" STREQUAL "OPTIONS")
                set(flag "--options")
            elseif("${arg}" STREQUAL "OPTIONS_HOST")
                set(flag "--options:host")
            elseif("${arg}" STREQUAL "OPTIONS_BUILD")
                set(flag "--options:build")
            elseif("${arg}" STREQUAL "PROFILE")
                set(flag "--profile")
            elseif("${arg}" STREQUAL "PROFILE_HOST")
                set(flag "--profile:host")
            elseif("${arg}" STREQUAL "PROFILE_BUILD")
                set(flag "--profile:build")
            elseif("${arg}" STREQUAL "SETTINGS")
                set(flag "--settings")
            elseif("${arg}" STREQUAL "SETTINGS_HOST")
                set(flag "--settings:host")
            elseif("${arg}" STREQUAL "SETTINGS_BUILD")
                set(flag "--settings:build")
            endif()
            list(LENGTH ARGS_${arg} numargs)
            foreach(item ${ARGS_${arg}})
                if(${item} STREQUAL "all" AND ${arg} STREQUAL "BUILD")
                    set(${arg} "--build")
                    break()
                endif()
                set(${arg} ${${arg}} ${flag} ${item})
            endforeach()
        endif()
    endforeach()
    if(DEFINED UPDATE)
        set(UPDATE --update)
    endif()
    if(DEFINED BASE)
        set(BASE --base)
    endif()
    set(lock_create_Args lock create ${PATH} ${REFERENCE} ${UPDATE} ${BASE} ${REMOTE} ${LOCKFILE} ${LOCKFILE_OUT} ${LOCKFILE_NODE_ID} ${INSTALL_FOLDER}
                                ${GENERATOR} ${BUILD} ${ENV} ${ENV_HOST} ${ENV_BUILD} ${OPTIONS} ${OPTIONS_HOST} ${OPTIONS_BUILD} 
                                ${PROFILE} ${PROFILE_HOST} ${PROFILE_BUILD} ${SETTINGS} ${SETTINGS_HOST} ${SETTINGS_BUILD})

    string(REPLACE ";" " " _lock_create_Args "${lock_create_Args}")
    message(STATUS "Conan executing: ${CONAN_CMD} ${_lock_create_Args}")
    
    if(ARGS_OUTPUT_QUIET)
      set(OUTPUT_OPT OUTPUT_QUIET)
    endif()
    if(ARGS_ERROR_QUIET)
      set(ERROR_OPT ERROR_QUIET)
    endif()

    execute_process(COMMAND ${CONAN_CMD} ${lock_create_Args}
                    RESULT_VARIABLE return_code
                    ${OUTPUT_OPT}
                    ${ERROR_OPT}
                    WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR})

    if(NOT "${return_code}" STREQUAL "0")
        if (ARGS_ERROR_QUIET)
            message(WARNING "Conan lock create failed='${return_code}'")
        else()
            message(FATAL_ERROR "Conan lock create failed='${return_code}'")
        endif()
    endif()
endfunction()

function(conan_cmake_setup_conanfile)
  conan_parse_arguments(${ARGV})
  if(ARGUMENTS_CONANFILE)
    get_filename_component(_CONANFILE_NAME ${ARGUMENTS_CONANFILE} NAME)
    # configure_file will make sure cmake re-runs when conanfile is updated
    configure_file(${ARGUMENTS_CONANFILE} ${CMAKE_CURRENT_BINARY_DIR}/${_CONANFILE_NAME}.junk COPYONLY)
    file(REMOVE ${CMAKE_CURRENT_BINARY_DIR}/${_CONANFILE_NAME}.junk)
  else()
    conan_cmake_generate_conanfile(ON ${ARGV})
  endif()
endfunction()

function(conan_cmake_configure)
    conan_cmake_generate_conanfile(OFF ${ARGV})
endfunction()

# Generate, writing in disk a conanfile.txt with the requires, options, and imports
# specified as arguments
# This will be considered as temporary file, generated in CMAKE_CURRENT_BINARY_DIR)
function(conan_cmake_generate_conanfile DEFAULT_GENERATOR)

    conan_parse_arguments(${ARGV})

    set(_FN "${CMAKE_CURRENT_BINARY_DIR}/conanfile.txt")
    file(WRITE ${_FN} "")

    if(DEFINED ARGUMENTS_REQUIRES)
        file(APPEND ${_FN} "[requires]\n")
        foreach(REQUIRE ${ARGUMENTS_REQUIRES})
            file(APPEND ${_FN} ${REQUIRE} "\n")
        endforeach()
    endif()

    if (DEFAULT_GENERATOR OR DEFINED ARGUMENTS_GENERATORS)
        file(APPEND ${_FN} "[generators]\n")
        if (DEFAULT_GENERATOR)
            file(APPEND ${_FN} "cmake\n")
        endif()
        if (DEFINED ARGUMENTS_GENERATORS)
            foreach(GENERATOR ${ARGUMENTS_GENERATORS})
                file(APPEND ${_FN} ${GENERATOR} "\n")
            endforeach()
        endif()
    endif()

    if(DEFINED ARGUMENTS_BUILD_REQUIRES)
        file(APPEND ${_FN} "[build_requires]\n")
        foreach(BUILD_REQUIRE ${ARGUMENTS_BUILD_REQUIRES})
            file(APPEND ${_FN} ${BUILD_REQUIRE} "\n")
        endforeach()
    endif()

    if(DEFINED ARGUMENTS_IMPORTS)
        file(APPEND ${_FN} "[imports]\n")
        foreach(IMPORTS ${ARGUMENTS_IMPORTS})
            file(APPEND ${_FN} ${IMPORTS} "\n")
        endforeach()
    endif()

    if(DEFINED ARGUMENTS_OPTIONS)
        file(APPEND ${_FN} "[options]\n")
        foreach(OPTION ${ARGUMENTS_OPTIONS})
            file(APPEND ${_FN} ${OPTION} "\n")
        endforeach()
    endif()

endfunction()


macro(conan_load_buildinfo)
    if(CONAN_CMAKE_MULTI)
      set(_CONANBUILDINFO conanbuildinfo_multi.cmake)
    else()
      set(_CONANBUILDINFO conanbuildinfo.cmake)
    endif()
    if(ARGUMENTS_INSTALL_FOLDER)
        set(_CONANBUILDINFOFOLDER ${ARGUMENTS_INSTALL_FOLDER})
    else()
        set(_CONANBUILDINFOFOLDER ${CMAKE_CURRENT_BINARY_DIR})
    endif()
    # Checks for the existence of conanbuildinfo.cmake, and loads it
    # important that it is macro, so variables defined at parent scope
    if(EXISTS "${_CONANBUILDINFOFOLDER}/${_CONANBUILDINFO}")
      message(STATUS "Conan: Loading ${_CONANBUILDINFO}")
      include(${_CONANBUILDINFOFOLDER}/${_CONANBUILDINFO})
    else()
      message(FATAL_ERROR "${_CONANBUILDINFO} doesn't exist in ${CMAKE_CURRENT_BINARY_DIR}")
    endif()
endmacro()


macro(conan_cmake_run)
    conan_parse_arguments(${ARGV})

    if(ARGUMENTS_CONFIGURATION_TYPES AND NOT CMAKE_CONFIGURATION_TYPES)
        message(WARNING "CONFIGURATION_TYPES should only be specified for multi-configuration generators")
    elseif(ARGUMENTS_CONFIGURATION_TYPES AND ARGUMENTS_BUILD_TYPE)
        message(WARNING "CONFIGURATION_TYPES and BUILD_TYPE arguments should not be defined at the same time.")
    endif()

    if(CMAKE_CONFIGURATION_TYPES AND NOT CMAKE_BUILD_TYPE AND NOT CONAN_EXPORTED
            AND NOT ARGUMENTS_BUILD_TYPE)
        set(CONAN_CMAKE_MULTI ON)
        if (NOT ARGUMENTS_CONFIGURATION_TYPES)
            set(ARGUMENTS_CONFIGURATION_TYPES "Release;Debug")
        endif()
        message(STATUS "Conan: Using cmake-multi generator")
    else()
        set(CONAN_CMAKE_MULTI OFF)
    endif()

    if(NOT CONAN_EXPORTED)
        conan_cmake_setup_conanfile(${ARGV})
        if(CONAN_CMAKE_MULTI)
            foreach(CMAKE_BUILD_TYPE ${ARGUMENTS_CONFIGURATION_TYPES})
                set(ENV{CONAN_IMPORT_PATH} ${CMAKE_BUILD_TYPE})
                conan_cmake_settings(settings ${ARGV})
                old_conan_cmake_install(SETTINGS ${settings} ${ARGV})
            endforeach()
            set(CMAKE_BUILD_TYPE)
        else()
            conan_cmake_settings(settings ${ARGV})
            old_conan_cmake_install(SETTINGS ${settings} ${ARGV})
        endif()
    endif()

    if (NOT ARGUMENTS_NO_LOAD)
      conan_load_buildinfo()
    endif()

    if(ARGUMENTS_BASIC_SETUP)
        foreach(_option CMAKE_TARGETS KEEP_RPATHS NO_OUTPUT_DIRS SKIP_STD)
            if(ARGUMENTS_${_option})
                if(${_option} STREQUAL "CMAKE_TARGETS")
                    list(APPEND _setup_options "TARGETS")
                else()
                    list(APPEND _setup_options ${_option})
                endif()
            endif()
        endforeach()
        conan_basic_setup(${_setup_options})
    endif()
endmacro()

macro(conan_check)
    # Checks conan availability in PATH
    # Arguments REQUIRED, DETECT_QUIET and VERSION are optional
    # Example usage:
    #    conan_check(VERSION 1.0.0 REQUIRED)
    set(options REQUIRED DETECT_QUIET)
    set(oneValueArgs VERSION)
    cmake_parse_arguments(CONAN "${options}" "${oneValueArgs}" "" ${ARGN})
    if(NOT CONAN_DETECT_QUIET)
        message(STATUS "Conan: checking conan executable")
    endif()

    find_program(CONAN_CMD conan)
    if(NOT CONAN_CMD AND CONAN_REQUIRED)
        message(FATAL_ERROR "Conan executable not found! Please install conan.")
    endif()
    if(NOT CONAN_DETECT_QUIET)
        message(STATUS "Conan: Found program ${CONAN_CMD}")
    endif()

endmacro()

function(VALIDATE_CONAN_VERSION)
    find_program(CONAN_EXECUTABLE conan)

    if (NOT CONAN_EXECUTABLE)
        message(FATAL_ERROR "Conan is not installed or not found in PATH.")
    endif()

    # Check Conan version
    execute_process(
        COMMAND "${CONAN_EXECUTABLE}" --version
        OUTPUT_VARIABLE CONAN_VERSION_OUTPUT
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )

    # Extract version numbers
    string(REGEX MATCH "([0-9]+)\\.([0-9]+)\\.([0-9]+)" CONAN_VERSION ${CONAN_VERSION_OUTPUT})

    if (CONAN_VERSION VERSION_LESS "2.0.0")
        message(FATAL_ERROR "Conan version 2.0.0 or higher is required. Found version: ${CONAN_VERSION}")
    else()
        message(STATUS "Found Conan version ${CONAN_VERSION}")
    endif()
endfunction()


function(ADD_CONAN_REMOTE)
    cmake_parse_arguments(CONAN_REMOTE "NO_FORCE;LOGIN" "URL;NAME;LOGIN_USERNAME;LOGIN_PASSWORD;EXECUTABLE" "" ${ARGN})
    if(NOT CONAN_REMOTE_URL OR NOT CONAN_REMOTE_NAME)
        message(FATAL_ERROR "CONAN_ADD_REMOTE must be called with URL and NAME arguments!")
    endif()

    if(CONAN_REMOTE_LOGIN AND (NOT CONAN_REMOTE_LOGIN_USERNAME OR NOT CONAN_REMOTE_LOGIN_PASSWORD))
        message(FATAL_ERROR "CONAN_ADD_REMOTE with LOGIN option must be called with LOGIN_USERNAME and LOGIN_PASSWORD arguments!")
    endif()

    if(NOT CONAN_EXECUTABLE)
        set(CONAN_EXECUTABLE "conan")
    endif()

    if(CONAN_REMOTE_NO_FORCE)
        set(FORCE_FLAG)
    else()
        set(FORCE_FLAG --force)
    endif()
    execute_process(COMMAND
            ${CONAN_EXECUTABLE} remote add
            ${CONAN_REMOTE_NAME}
            ${CONAN_REMOTE_URL}
            ${FORCE_FLAG}
        )

    if(CONAN_REMOTE_LOGIN)
        execute_process(COMMAND
            ${CONAN_EXECUTABLE} remote login
            ${CONAN_REMOTE_NAME}
            ${CONAN_REMOTE_LOGIN_USERNAME}
            -p ${CONAN_REMOTE_LOGIN_PASSWORD}
        )
    endif()
endfunction()

function(conan_add_remotes)
    message(STATUS "Conan: Adding medicdeps remote repository")
    execute_process(COMMAND conan remote add --index 1 medicdeps https://artifactory.medicteam.io/artifactory/api/conan/medicdeps RESULT_VARIABLE return_code ERROR_QUIET)
    if(NOT "${return_code}" STREQUAL "0")
      message(STATUS "Conan: medicdeps already exists. Updating its index and URL...")
      execute_process(COMMAND conan remote update medicdeps --index 1 --url https://artifactory.medicteam.io/artifactory/api/conan/medicdeps RESULT_VARIABLE return_code ERROR_QUIET)
      if(NOT "${return_code}" STREQUAL "0")
        message(FATAL_ERROR "Conan remote update failed='${return_code}'.")
      endif()
    endif()

    message(STATUS "Conan: Adding medicdeps-clang remote repository")
    execute_process(COMMAND conan remote add --index 3 medicdeps-clang https://artifactory.medicteam.io/artifactory/api/conan/medicdeps-clangCL RESULT_VARIABLE return_code ERROR_QUIET)
    if(NOT "${return_code}" STREQUAL "0")
      message(STATUS "Conan: medicdeps-clang already exists. Updating its index and URL...")
      execute_process(COMMAND conan remote update medicdeps-clang --index 3 --url https://artifactory.medicteam.io/artifactory/api/conan/medicdeps-clangCL RESULT_VARIABLE return_code ERROR_QUIET)
      if(NOT "${return_code}" STREQUAL "0")
        message(FATAL_ERROR "Conan remote update failed='${return_code}'.")
      endif()
    endif()
    
    if(NOT ${SKIP_XLAB_INTERNAL})
        message(STATUS "Conan: Adding XLAB internal remote repository")
        execute_process(COMMAND conan remote add --index 2 xlab_internal https://artifactory.medicteam.io/artifactory/api/conan/xlab_internal_conanv2 RESULT_VARIABLE return_code ERROR_QUIET)
        if(NOT "${return_code}" STREQUAL "0")
        message(STATUS "Conan: xlab_internal already exists. Updating its index and URL...")
        execute_process(COMMAND conan remote update xlab_internal --index 2 --url https://artifactory.medicteam.io/artifactory/api/conan/xlab_internal_conanv2 RESULT_VARIABLE return_code ERROR_QUIET)
        if(NOT "${return_code}" STREQUAL "0")
            message(FATAL_ERROR "Conan remote update failed='${return_code}'.")
        endif()
        endif()

        if(DEFINED ENV{XLAB_INTERNAL_CONAN_USER} AND DEFINED ENV{XLAB_INTERNAL_CONAN_PASSWORD})
            message(STATUS "Conan: Logging to conan remote xlab_internal with user $ENV{XLAB_INTERNAL_CONAN_USER}...")
            execute_process(COMMAND conan remote login xlab_internal $ENV{XLAB_INTERNAL_CONAN_USER} -p $ENV{XLAB_INTERNAL_CONAN_PASSWORD}
                        RESULT_VARIABLE return_code)                                
            if(NOT "${return_code}" STREQUAL "0")                                       
                message(FATAL_ERROR "Conan remote login failed with code '${return_code}'")         
            endif()
        else()
            message(FATAL_ERROR "Conan: XLAB_INTERNAL_CONAN_USER and XLAB_INTERNAL_CONAN_PASSWORD environment variables are not set.")
        endif()
    else()
        mesage(STATUS "Conan: Removing XLAB internal remote repository")
        execute_process(COMMAND conan remote remove xlab_internal https://artifactory.medicteam.io/artifactory/api/conan/xlab_internal_conanv2 RESULT_VARIABLE return_code ERROR_QUIET)
    endif()

endfunction()

macro(conan_config_install)
    # install a full configuration from a local or remote zip file
    # Argument ITEM is required, arguments TYPE, SOURCE, TARGET and VERIFY_SSL are optional
    # Example usage:
    #    conan_config_install(ITEM https://github.com/conan-io/cmake-conan.git
    #       TYPE git SOURCE source-folder TARGET target-folder VERIFY_SSL false)
    set(oneValueArgs ITEM TYPE SOURCE TARGET VERIFY_SSL)
    set(multiValueArgs ARGS)
    cmake_parse_arguments(CONAN "" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    if(DEFINED CONAN_COMMAND)
        set(CONAN_CMD ${CONAN_COMMAND})
    else()
        conan_check(REQUIRED)
    endif()

    if(DEFINED CONAN_VERIFY_SSL)
	set(CONAN_VERIFY_SSL_ARG "--verify-ssl=${CONAN_VERIFY_SSL}")
    endif()

    if(DEFINED CONAN_TYPE)
	set(CONAN_TYPE_ARG "--type=${CONAN_TYPE}")
    endif()

    if(DEFINED CONAN_ARGS)
	# Convert ; seperated multi arg list into space seperated string
	string(REPLACE ";" " " l_CONAN_ARGS "${CONAN_ARGS}")
	set(CONAN_ARGS_ARGS "--args=${l_CONAN_ARGS}")
    endif()

    if(DEFINED CONAN_SOURCE)
	set(CONAN_SOURCE_ARGS "--source-folder=${CONAN_SOURCE}")
    endif()

    if(DEFINED CONAN_TARGET)
	set(CONAN_TARGET_ARGS "--target-folder=${CONAN_TARGET}")
    endif()

    set (CONAN_CONFIG_INSTALL_ARGS 	${CONAN_VERIFY_SSL_ARG}
					${CONAN_TYPE_ARG}
					${CONAN_ARGS_ARGS}
					${CONAN_SOURCE_ARGS}
					${CONAN_TARGET_ARGS})

    message(STATUS "Conan: Installing config from ${CONAN_ITEM}")
	execute_process(COMMAND ${CONAN_CMD} config install ${CONAN_ITEM} ${CONAN_CONFIG_INSTALL_ARGS}
                  RESULT_VARIABLE return_code)
  if(NOT "${return_code}" STREQUAL "0")
    message(FATAL_ERROR "Conan config failed='${return_code}'")
  endif()
endmacro()


function(conan_cmake_profile)
    set(profileOneValueArgs   FILEPATH)
    set(profileMultiValueArgs SETTINGS OPTIONS CONF ENV BUILDENV RUNENV TOOL_REQUIRES)
    cmake_parse_arguments(ARGS "" "${profileOneValueArgs}" "${profileMultiValueArgs}" ${ARGN})

    if(DEFINED ARGS_FILEPATH)  
        set(_FN "${ARGS_FILEPATH}")
    else()
        set(_FN "${CMAKE_CURRENT_BINARY_DIR}/profile")
    endif()
    message(STATUS "Conan: Creating profile ${_FN}")
    file(WRITE ${_FN} "")

    if(DEFINED ARGS_SETTINGS)
        file(APPEND ${_FN} "[settings]\n")
        foreach(SETTING ${ARGS_SETTINGS})
            file(APPEND ${_FN} ${SETTING} "\n")
        endforeach()
    endif()

    if(DEFINED ARGS_OPTIONS)
        file(APPEND ${_FN} "[options]\n")
        foreach(OPTION ${ARGS_OPTIONS})
            file(APPEND ${_FN} ${OPTION} "\n")
        endforeach()
    endif()

    if(DEFINED ARGS_CONF)
        file(APPEND ${_FN} "[conf]\n")
        foreach(CONF ${ARGS_CONF})
            file(APPEND ${_FN} ${CONF} "\n")
        endforeach()
    endif()

    if(DEFINED ARGS_ENV)
        file(APPEND ${_FN} "[env]\n")
        foreach(ENV ${ARGS_ENV})
            file(APPEND ${_FN} ${ENV} "\n")
        endforeach()
    endif()

    if(DEFINED ARGS_BUILDENV)
        file(APPEND ${_FN} "[buildenv]\n")
        foreach(BUILDENV ${ARGS_BUILDENV})
            file(APPEND ${_FN} ${BUILDENV} "\n")
        endforeach()
    endif()

    if(DEFINED ARGS_RUNENV)
        file(APPEND ${_FN} "[runenv]\n")
        foreach(RUNENV ${ARGS_RUNENV})
            file(APPEND ${_FN} ${RUNENV} "\n")
        endforeach()
    endif()

    if(DEFINED ARGS_TOOL_REQUIRES)
        file(APPEND ${_FN} "[tool_requires]\n")
        foreach(TOOL_REQUIRE ${ARGS_TOOL_REQUIRES})
            file(APPEND ${_FN} ${TOOL_REQUIRE} "\n")
        endforeach()
    endif()
endfunction()
