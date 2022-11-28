#include <gtest/gtest.h>

#include <filesystem>
#include <fstream>

#include "image_file.h"

TEST(EmbedFiles, FileCountTest) {
  auto n_files = image::GetFileCount();
  ASSERT_EQ(image::GetFileCount(), 1);
}

TEST(EmbedFiles, FileNameTest) {
  auto files = image::GetFiles();
  ASSERT_EQ(image::GetFileCount(), 1);
  auto file = files[0];
  ASSERT_STREQ(file.path, "image.jpg");
}

TEST(EmbedFiles, FileContentTest) {
  auto files = image::GetFiles();
  ASSERT_EQ(image::GetFileCount(), 1);
  auto file = files[0];
  auto size = std::filesystem::file_size(FILE_PATH);
  ASSERT_EQ(file.size, size);
  std::ifstream ifile(FILE_PATH, std::ios::binary);
  ASSERT_TRUE(ifile.good());
  std::vector<char> buffer(size);
  ifile.read(buffer.data(), buffer.size());
  auto* data = reinterpret_cast<uint8_t*>(buffer.data());
  for (int i = 0; i < size; ++i) {
    EXPECT_EQ(data[i], file.data[i]);
  }
}
