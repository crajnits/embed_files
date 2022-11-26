#include <algorithm>
#include <cstring>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <map>
#include <sstream>
#include <vector>

// Embed files generator.
// This file is intended to be invoked from embed_files.cmake. It is not
// intended to be invoked directly from the command line.
// TODO: Remove redundant string copies.

using KeyMap = std::map<std::string, std::string>;

std::string GetDefArg(std::string_view option, const char* def) {
  if (def) return def;
  std::cout << "[ERROR]: " << option << " arg missing." << std::endl;
  std::exit(-1);
}

std::string_view StripWhitespaces(std::string_view str) {
  std::string_view whitespace = " \r\n\t\v\f";
  auto ltrim = [&whitespace](std::string_view str) {
    const auto pos(str.find_first_not_of(whitespace));
    str.remove_prefix(std::min(pos, str.length()));
    return str;
  };

  auto rtrim = [&whitespace](std::string_view str) {
    const auto pos(str.find_last_not_of(whitespace));
    str.remove_suffix(std::min(str.length() - pos - 1, str.length()));
    return str;
  };

  return ltrim(rtrim(str));
}

std::string GetArgOption(std::string_view args, std::string_view option,
                         const char* def = nullptr) {
  auto start_pos = args.find(option);
  if (start_pos == std::string::npos) return GetDefArg(option, def);
  auto arg_start_pos = args.find(" ", start_pos);
  if (arg_start_pos == std::string::npos) return GetDefArg(option, def);
  auto arg_end_pos = args.find("--", arg_start_pos);
  auto arg = args.substr(arg_start_pos, arg_end_pos - arg_start_pos);
  arg = StripWhitespaces(arg);
  return arg.empty() ? GetDefArg(option, def) : std::string(arg);
}

template <typename... Args>
std::string StrCat(Args const&... args) {
  std::ostringstream stream;
  using List = int[];
  (void)List{0, ((void)(stream << args), 0)...};
  return stream.str();
}

std::vector<std::string> Split(std::string_view s, char delim = ',') {
  std::vector<std::string> result;
  std::string input{s};
  std::stringstream ss(input);
  std::string item;
  while (std::getline(ss, item, delim)) {
    result.push_back(item);
  }
  return result;
}

std::string ToCamelCase(std::string_view str) {
  bool cap_next = true;
  std::string output;
  output.reserve(str.size());
  for (auto ch : str) {
    if (ch == '_') {
      cap_next = true;
    } else if (cap_next) {
      output.push_back(std::toupper(ch));
      cap_next = false;
    } else {
      output.push_back(ch);
    }
  }
  return output;
}

std::string FindAndReplace(std::string string, const KeyMap& key_map) {
  for (const auto& [key, value] : key_map) {
    size_t pos = 0;
    while ((pos = string.find(key)) != std::string::npos) {
      string.replace(pos, key.length(), value);
    }
  }
  return string;
}

const char* kHeaderTemplate =
    R"(// Auto-generated file created using the embed_files tool.
#pragma once

#include <inttypes.h>
#include <stddef.h>

${namespace_start}

struct ${prefix}FileView {
    const char* path;
    const char* data;
    size_t size;
};

const ${prefix}FileView* ${prefix}GetFiles();

int ${prefix}FileCount();

${namespace_end}
)";

const char* kSourceTemplate =
    R"(// Auto-generated file created using the embed_files tool.
#include "${header_filename}"

${namespace_start}
namespace {

${file_data}

const ${prefix}FileView files[] = {
${file_view_list}
};

}  // namespace

const ${prefix}FileView* ${prefix}GetFiles() {
  return files;
}

int ${prefix}FileCount() {
  return sizeof(files) / sizeof(*files);
}

${namespace_end}
)";

const char* kDataTemplate =
    R"(const char kData${idx}[] = {
${data_lines}
};

)";

const char* kFileViewTemplate =
    R"(  {"${path}", kData${idx}, sizeof(kData${idx})},
)";

int main(int argc, char** argv) {
  // Parse input args.
  // Space-separated command-line arguments are handled differently on different
  // platforms. To address this, all arguments are be merged into a single
  // string first, and then string search methods are be used to extract the
  // desired arguments in a platform-agnostic way.
  std::stringstream args_stream;
  for (int i = 0; i < argc; ++i) {
    // std::printf("Arg[%d]:%s\n", i, argv[i]);
    args_stream << argv[i] << " ";
  }
  auto args = args_stream.str();
  auto header_filepath = GetArgOption(args, "--header_filepath");
  auto source_filepath = GetArgOption(args, "--source_filepath");
  auto name_space = GetArgOption(args, "--namespace", "");
  auto prefix = ToCamelCase(GetArgOption(args, "--prefix", ""));
  auto filepaths = Split(GetArgOption(args, "--filepaths"));
  auto filepaths_strip = Split(GetArgOption(args, "--filepaths_strip"));

  // Varidate file list.
  if (filepaths.empty() || filepaths_strip.size() != filepaths.size()) {
    std::printf("[ERROR]: Invalid filepaths size.\n");
    return -1;
  }

  // Namespace variables.
  std::string namespace_start =
      name_space.size() ? StrCat("namespace ", name_space, " {") : "";
  std::string namespace_end =
      name_space.size() ? StrCat("}  // namespace ", name_space) : "";

  // Keymap for header file.
  KeyMap key_map{
      {"${namespace_start}", namespace_start},
      {"${namespace_end}", namespace_end},
      {"${prefix}", prefix},
  };

  // header file
  std::filesystem::create_directories(
      std::filesystem::path(header_filepath).parent_path());
  std::ofstream header_file(header_filepath);
  if (!header_file.good()) {
    std::printf("[ERROR]: %s open failed\n", header_filepath.c_str());
    return -1;
  }
  header_file << FindAndReplace(kHeaderTemplate, key_map);

  // Read each input file.
  std::string file_data;
  std::string file_view_list;
  for (int idx = 0; idx < filepaths.size(); ++idx) {
    const auto& filepath = filepaths[idx];
    std::ifstream file(filepath.c_str(), std::ios::binary);
    if (!file.good()) {
      std::printf("[ERROR]: %s open failed\n", filepath.c_str());
      return -1;
    }
    char buffer[12] = {};
    std::stringstream lines;
    while (!file.eof()) {
      file.read(buffer, sizeof(buffer));
      auto bytes_read = static_cast<int>(file.gcount());
      // first char.
      if (bytes_read)
        lines << "  0x" << std::hex << std::setfill('0') << std::setw(2)
              << (int)buffer[0];
      for (auto i = 1; i < (bytes_read - 1); ++i)
        lines << ", 0x" << std::hex << std::setfill('0') << std::setw(2)
              << (int)buffer[i];
      // last char.
      if (bytes_read)
        lines << ", 0x" << std::hex << std::setfill('0') << std::setw(2)
              << (int)buffer[bytes_read - 1] << ",\n";
    }
    lines << "  0x00";
    KeyMap data_map{
        {"${idx}", std::to_string(idx)},
        {"${data_lines}", lines.str()},
        {"${path}", filepaths_strip[idx]},
    };
    file_data += FindAndReplace(kDataTemplate, data_map);
    file_view_list += FindAndReplace(kFileViewTemplate, data_map);
  }

  // Update key_map for source file.
  auto header_filename =
      std::filesystem::path(header_filepath).filename().string();
  key_map.insert({"${header_filename}", header_filename});
  key_map.insert({"${file_data}", file_data});
  key_map.insert({"${file_view_list}", file_view_list});

  // Open source file.
  std::filesystem::create_directories(
      std::filesystem::path(source_filepath).parent_path());
  std::ofstream source_file(source_filepath.c_str());
  if (!source_file.good()) {
    std::printf("[ERROR]: %s open failed\n", source_filepath.c_str());
    return -1;
  }
  source_file << FindAndReplace(kSourceTemplate, key_map);
  return 0;
}
