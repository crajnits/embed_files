include_guard(GLOBAL)

# macro to set the host machine executable suffix.
# variable: __host_executable_suffix
macro(set_host_executable_suffix)
  if (CMAKE_CROSSCOMPILING)
    if (CMAKE_HOST_WIN32)
      set(__host_executable_suffix ".exe")
    else()
      set(__host_executable_suffix "")
    endif()
  else()
    set(__host_executable_suffix ${CMAKE_EXECUTABLE_SUFFIX})
  endif()
endmacro()

# embed_files()
#
# CMake function to embed a file into a library at compile time.
#
# This function generates a <target_name>.h header file with a function to get the file content.
#
# Parameters:
# target_name: (Required) The target name to which the file will be added.
# ALIAS:       (Optional) The alias target name for the TARGET.
# NAMESPACE:   (Optional) The namespace for the header file.
#                         No namespace will be used if not passed.
# PREFIX:      (Optional) Function and class names will be prefixed with this value.
#                         The target name will be used if not passed.
# FILES:       (Required) The files (one or more) to embed.
#
# embed_files(yuv2rgb_kernel
#     ALIAS yuv2rgb::kernel
#     NAMESPACE yuv2rgb
#     FILES yuv420_to_rgba.cl rgba_to_yuv.cl
# )
function(embed_files target_name)
    # Parse function args.
    set(options "")
    set(one_value_args ALIAS NAMESPACE PREFIX)
    set(multi_value_args FILES)
    cmake_parse_arguments(EMBED "${options}" "${one_value_args}" "${multi_value_args}" ${ARGN})
    # Set variables.
    set(OUT_DIR ${CMAKE_CURRENT_BINARY_DIR}/embed_files.gen)
    get_filename_component(source_abs_path ${OUT_DIR}/${target_name}.cpp ABSOLUTE)
    get_filename_component(header_abs_path ${OUT_DIR}/${target_name}.h ABSOLUTE)
    # Get the comma seperated embed file list.
    set(FILE_LIST "")
    set(FILE_LIST_STRIP "")
    foreach(embed_file ${EMBED_FILES})
        get_filename_component(embed_file_abs_path ${embed_file} ABSOLUTE)
        string(APPEND FILE_LIST "${embed_file_abs_path},")
        string(APPEND FILE_LIST_STRIP "${embed_file},")
    endforeach()

    # Executable target to generate sources.
    # Cross compilation is supported by using a custom command target instead of add_executable
    if(NOT TARGET __embed_files_target)
      set(__bin_dir "${CMAKE_BINARY_DIR}/__embed_files")
      set(__src_dir "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/source")
      set_host_executable_suffix()
      set(__embed_files "${__bin_dir}/embed_files${__host_executable_suffix}")
      # message(INFO "__embed_files: ${__embed_files}")
      add_custom_command(
          OUTPUT ${__embed_files}
          COMMAND ${CMAKE_COMMAND}
              -DCMAKE_BUILD_TYPE:STRING="Release"
              -DCMAKE_RUNTIME_OUTPUT_DIRECTORY_RELEASE:PATH="${__bin_dir}"
              -B"${__bin_dir}"
              -S"${__src_dir}"
          COMMAND ${CMAKE_COMMAND} --build "${__bin_dir}" --config Release
          DEPENDS "${__src_dir}/embed_files.cpp"
                  "${__src_dir}/CMakeLists.txt"
          # WORKING_DIRECTORY "${__bin_dir}"
          COMMENT "Generating 'embed_files${__host_executable_suffix}'."
      )
      # define tool target.
      add_custom_target(__embed_files_target
          DEPENDS ${__embed_files}
      )
      set_target_properties(__embed_files_target PROPERTIES __embed_files_exe "${__embed_files}")
    endif()

    # Get the prefix.
    set(PREFIX "${EMBED_PREFIX}")
    if("${PREFIX}" STREQUAL "")
        set(PREFIX "${target_name}")
    endif()
    string(MAKE_C_IDENTIFIER "${PREFIX}" PREFIX)
    # Call cpp executable to generate source and header.
    set(ARGS "--header_filepath ${header_abs_path}   \
              --source_filepath ${source_abs_path}   \
              --namespace ${EMBED_NAMESPACE}         \
              --prefix ${PREFIX}                     \
              --filepaths ${FILE_LIST}               \
              --filepaths_strip ${FILE_LIST_STRIP}   \
             ")
    # message(INFO ${ARGS})
    get_target_property(__embed_files_exe __embed_files_target __embed_files_exe)
    add_custom_command(
        OUTPUT ${source_abs_path} ${header_abs_path}
        COMMAND ${__embed_files_exe} ${ARGS}
        COMMENT "Generating embed file at '${header_abs_path}'."
        DEPENDS __embed_files_target ${EMBED_FILES}
    )
    # Create library target with generated source and header file.
    add_library(${target_name} STATIC
        ${source_abs_path}
        ${header_abs_path}
    )
    target_include_directories(${target_name} PUBLIC ${OUT_DIR})
    if(NOT "${EMBED_ALIAS}" STREQUAL "")
        add_library(${EMBED_ALIAS} ALIAS ${target_name})
    endif()
endfunction()
