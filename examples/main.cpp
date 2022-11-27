#include <iostream>

#include "matmul_kernel.h"

int main() {
  // Number of files embed in "matmul_kernel" target.
  auto n_files = MatmulKernelFileCount();  // 1
  std::cout << "Number of files: " << n_files << std::endl;
  // first file handle.
  auto file = MatmulKernelGetFiles()[0];
  // file name, the same as provided in the embed_files CMake target.
  std::cout << "FileName: " << file.path << std::endl;  // "matmul_kernel.cl"
  // Total File size.
  std::cout << "FileSize: " << file.size << std::endl;
  // Starting address of file content. explicitly null-terminated char array.
  char* file_data = file.data;
  // ... use the file data ...
  std::cout << file.data << std::endl;
  // ... other code ...
  return 0;
}
