cmake_minimum_required(VERSION 3.14)

project(matmul)

# For standalone build, replace ../ with embed_files path.
include(../embed_files.cmake)

# embed_files target
embed_files(matmul_kernel
    FILES matmul_kernel.cl
)

# executable target.
add_executable(matmul_test
    main.cpp
)
target_link_libraries(matmul_test
    PRIVATE matmul_kernel
)
