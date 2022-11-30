include(FetchContent)

FetchContent_Declare(googletest
    GIT_REPOSITORY https://github.com/google/googletest.git
    GIT_TAG HEAD
)

# For Windows: Prevent overriding the parent project's compiler/linker settings
set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)
FetchContent_MakeAvailable(googletest)

embed_files(image_file
    ALIAS image::file
    NAMESPACE image
    PREFIX \"\" # empty function prefix, target name will be used if not passed.
    FILES image.jpg
)

add_executable(embed_files_test
    embed_files_test.cpp
)
target_compile_definitions(embed_files_test
    PRIVATE FILE_PATH="${CMAKE_CURRENT_SOURCE_DIR}/image.jpg"  # filepath for testing.
)
target_link_libraries(embed_files_test
    PRIVATE image::file
    PRIVATE GTest::gtest_main
)

include(GoogleTest)
gtest_discover_tests(embed_files_test)
