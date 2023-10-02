![Build Status](https://github.com/crajnits/embed_files/actions/workflows/main.yml/badge.svg)

# Embed Files

CMake and C++ based tool to embed resources, such as data, images, or source files such as shaders or OpenCL kernels, into a library at compile time. The generated header provides functions to access the embedded resources, eliminating the need to read them from storage at runtime.

The tool has no external dependencies and can be used on virtually any platform that supports CMake and a C++ compiler. It first compiles a native C++ utility executable for the host platform and uses it to dump the resource content into a generated source file. This results in significantly faster build times compared to pure CMake or scripting language based tools.

## Getting Started

Let's update your `CMakeLists.txt` file to add the following lines to get started with this project:

```cmake
project(your_project)

# 1. Clone the project to your local machine:
# git clone https://github.com/crajnits/embed_files.git
# Add the embed_files project to your project:
include(path/to/embed_files/embed_files.cmake)

# Alternatively, you can use CMake FetchContent to clone and add the embed_files
# project to your CMake project:
#
# include(FetchContent)
# FetchContent_Declare(
#     embed_files
#     GIT_REPOSITORY https://github.com/crajnits/embed_files.git
#     GIT_TAG HEAD # or replace with commit hash.
# )
# FetchContent_MakeAvailable(embed_files)

# 2. Create an embed_files target with a list of files to embed.
# This will generate a static library:
embed_files(matmul_kernel
  FILES matmul_kernel_1.cl matmul_kernel_2.cl
)

# ... other code ...
# ... Your target defination, eg matmul target.

# 3. Link the generated static library to your CMake target:
target_link_libraries(matmul
  PRIVATE matmul_kernel
)
```

4. Now, you can include the generated header in your source file and retrieve the data pointer, size, and name of the embedded files:

```cpp
#include <iostream>
#include "matmul_kernel.h"  // Generated header file.

int main() {
  // Number of files embed in "matmul_kernel" target.
  auto n_files = MatmulKernelGetFileCount();  // 2
  std::cout << "Number of files: " << n_files << std::endl;
  // first file handle.
  auto file = MatmulKernelGetFiles()[0];
  // file name, the same as provided in the embed_files CMake target.
  std::cout << "FileName: " << file.path << std::endl;  // "matmul_kernel_1.cl"
  // Total File size.
  std::cout << "FileSize: " << file.size << std::endl;
  // Starting address of file content. explicitly null-terminated char array.
  char* file_data = file.data;
  // ... use the file data ...
  std::cout << file.data << std::endl;
  // ... other code ...
  return 0;
}
```

For documentation on the `embed_files()` CMake function, please refer to [embed_files.cmake](embed_files.cmake#L17) file.
For examples of how to use this project, see the [examples](examples) directory.

## Contributing

Contributions are welcome! Please open a pull request on GitHub.

## License

This project is licensed under the MIT License.
