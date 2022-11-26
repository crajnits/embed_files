cmake_minimum_required(VERSION 3.14)

project(embed_files)
set(CMAKE_CXX_STANDARD 17)

include(embed_files.cmake)

if(${CMAKE_CURRENT_SOURCE_DIR} STREQUAL ${CMAKE_SOURCE_DIR})
    option(EMBED_FILES_BUILD_EXAMPLES "Build Embed Files Examples" ON)
    option(EMBED_FILES_BUILD_TESTS "Build Embed Files Test" ON)
    if(${EMBED_FILES_BUILD_EXAMPLES})
        add_subdirectory(examples)
    endif()
    if(${EMBED_FILES_BUILD_TESTS})
        enable_testing()
        add_subdirectory(tests)
    endif()
endif()
