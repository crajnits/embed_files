include_guard(GLOBAL)

# macro to get the host machine executable suffix.
# variable: __host_executable_suffix
macro(get_host_cmake_executable_suffix)
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
# This function generates a <TARGET>.h header file with a function to get the file content.
#
# Parameters:
# TARGET:    (Required) The target name to which the file will be added.
# ALIAS:     (Optional) The alias target name for the TARGET.
# NAMESPACE: (Optional) The namespace for the header file.
#                       No namespace will be used if not passed.
# PREFIX:    (Optional) Function and class names will be prefixed with this value.
#                       The target name will be used if not passed.
# FILES:     (Required) The files (one or more) to embed.
#
# embed_files(
#     TARGET yuv2rgb_kernel ALIAS yuv2rgb::kernel
#     NAMESPACE yuv2rgb
#     FILES yuv420_to_rgba.cl rgba_to_yuv.cl
# )
function(embed_files)
    # Parse function args.
    set(options "")
    set(one_value_args TARGET ALIAS NAMESPACE PREFIX)
    set(multi_value_args FILES)
    cmake_parse_arguments(EMBED "${options}" "${one_value_args}" "${multi_value_args}" ${ARGN})
    # Set variables.
    set(OUT_DIR ${CMAKE_CURRENT_BINARY_DIR}/embed_files.gen)
    get_filename_component(source_abs_path ${OUT_DIR}/${EMBED_TARGET}.cpp ABSOLUTE)
    get_filename_component(header_abs_path ${OUT_DIR}/${EMBED_TARGET}.h ABSOLUTE)
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
      get_host_cmake_executable_suffix()
      set(__embed_files "${__bin_dir}/embed_files${__host_executable_suffix}")
      set_property(GLOBAL PROPERTY __embed_files_exe "${__embed_files}")
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

      add_custom_target(__embed_files_target
          DEPENDS ${__embed_files}
      )
    endif()

    # Get the prefix.
    set(PREFIX "${EMBED_PREFIX}")
    if("${PREFIX}" STREQUAL "")
        set(PREFIX "${EMBED_TARGET}")
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
    get_property(__embed_files_exe GLOBAL PROPERTY __embed_files_exe)
    add_custom_command(
        OUTPUT ${source_abs_path} ${header_abs_path}
        COMMAND ${__embed_files_exe} ${ARGS}
        COMMENT "Generating embed file at '${header_abs_path}'."
        DEPENDS __embed_files_target ${EMBED_FILES}
    )
    # Create library target with generated source and header file.
    add_library(${EMBED_TARGET} STATIC
        ${source_abs_path}
        ${header_abs_path}
    )
    target_include_directories(${EMBED_TARGET} PUBLIC ${OUT_DIR})
    if(NOT "${EMBED_ALIAS}" STREQUAL "")
        add_library(${EMBED_ALIAS} ALIAS ${EMBED_TARGET})
    endif()
endfunction()
