#include "path.h"

#include <iostream>
#include <stdio.h>
#include <cstring>
#include <cstdio>

#if defined(_WIN32)

	#include "windows/path_windows.h"
	#define harq_get_app_path() windows_get_app_path()
	#define harq_is_file_exist(a) windows_is_file_exist(a)
	#define harq_create_directory(a) windows_create_directory(a)
	#define harq_get_path_root(a) windows_get_path_root(a)
	#define harq_get_directory_name(a) windows_get_directory_name(a)
	#define harq_get_filename(a) windows_get_filename(a)
	#define harq_get_full_path(a) windows_get_full_path(a)
	#define harq_get_file_size(a) windows_get_file_size(a)
	#define harq_get_no_ext(a) windows_get_no_ext(a)
	#define harq_get_file_ext(a) windows_get_file_ext(a)
	#define harq_remove_file(a) windows_remove_file(a)
	#define harq_is_directory_exist(a) windows_is_directory_exist(a)
	#define harq_is_directory(a) windows_is_directory(a)
	#define harq_get_dir_all_file(a, b) windows_get_dir_all_file(a, b)
	#define harq_get_dir_all(path, file_vector) windows_get_dir_all(path, file_vector);
	#define harq_get_dir_single(path, file_vector, file_type_vector) windows_get_dir_single(path, file_vector, file_type_vector);
	#define harq_get_file_create_timer(a) windows_get_file_create_timer(a)
	
#else
	
	#include "linux/path_linux.h"
	#define harq_get_app_path() linux_get_app_path()
	#define harq_is_file_exist(a) linux_is_file_exist(a)
	#define harq_create_directory(a) linux_create_directory(a)
	#define harq_get_path_root(a) linux_get_path_root(a)
	#define harq_get_directory_name(a) linux_get_directory_name(a)
	#define harq_get_filename(a) linux_get_filename(a)
	#define harq_get_full_path(a) linux_get_full_path(a)
	#define harq_get_file_size(a) linux_get_file_size(a)
	#define harq_get_no_ext(a) linux_get_no_ext(a)
	#define harq_get_file_ext(a) linux_get_file_ext(a)
	#define harq_remove_file(a) linux_remove_file(a)
	#define harq_is_directory_exist(a) linux_is_directory_exist(a)
	#define harq_is_directory(a) linux_is_directory(a)
	#define harq_get_dir_all_file(a, b) linux_get_dir_all_file(a, b)
	#define harq_get_dir_all(path, file_vector) linux_get_dir_all(path, file_vector);
	#define harq_get_dir_single(path, file_vector, file_type_vector) linux_get_dir_single(path, file_vector, file_type_vector);
	#define harq_get_file_create_timer(a) linux_get_file_create_timer(a)
	#define harq_postion_read_file(file_handle, postion, buffer, size) linux_postion_read_file(file_handle, postion, buffer, size)

	#define harq_file_handle int
#endif

namespace ustd
{
	path::path(void)
	{
	}

	path::~path(void)
	{
	}

	std::string path::get_app_path()
	{
		return harq_get_app_path();
	}

	bool path::create_directory(const char* path)
	{
		return harq_create_directory(path);
	}

	std::string path::get_no_ext(const std::string &file_path)
	{
		return harq_get_no_ext(file_path);
	}

	bool path::is_file_exist(const std::string &file_path)
	{
		return harq_is_file_exist(file_path);
	}

	std::string path::get_directory_name(const std::string &dir_path_name)
	{
		return harq_get_directory_name(dir_path_name);
	}

	bool path::is_directory(const std::string &dir_path)
	{
		return harq_is_directory(dir_path);
	}

	void path::get_dir_all_file(const char *path, std::vector<std::string> &file_vector)
	{
		return harq_get_dir_all_file(path, file_vector);
	}

	void path::get_dir_all(const char *path, std::vector<std::string> &file_vector)
	{
		return harq_get_dir_all(path, file_vector);
	}

	void path::get_dir_single(const char *path, std::vector<std::string> &file_vector, std::vector<int> &file_type_vector)
	{
		return harq_get_dir_single(path, file_vector, file_type_vector);
	}

	bool path::is_directory_exist(const std::string &path)
	{
		return harq_is_directory_exist(path);
	}

	std::string path::get_filename(const std::string &file_path)
	{
		return harq_get_filename(file_path);
	}

	long long path::get_file_size(const std::string &file_path)
	{
		return harq_get_file_size(file_path);
	}

	std::string path::get_file_ext(const std::string &file_path)
	{
		return harq_get_file_ext(file_path);
	}

	bool path::remove_file(const std::string &file_path)
	{
		return harq_remove_file(file_path);
	}

	time_t path::get_file_create_timer(const char *path)
	{
		return harq_get_file_create_timer(path);
	}

	std::string path::get_full_path(const std::string &file_path)
	{
		return harq_get_full_path(file_path);
	}
}
