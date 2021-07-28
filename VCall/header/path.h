#pragma once

#ifndef USTD_PATH_H_
#define USTD_PATH_H_

#include <string>
#include <vector>

namespace ustd
{

	class path
	{
	public:
		path(void);
		~path(void);

	public:
		static std::string get_app_path();
		static bool is_file_exist(const std::string &file_path);
		static bool create_directory(const char* path);
		static std::string get_path_root(const std::string &dir_path);
		static std::string get_directory_name(const std::string &dir_path_name);
		static std::string get_filename(const std::string &file_path);
		static std::string get_full_path(const std::string &file_path);
		static long long get_file_size(const std::string &file_path);
		static std::string get_no_ext(const std::string &file_path);
		static std::string get_file_ext(const std::string &file_path);
		static bool remove_file(const std::string &file_path);
		static bool is_directory_exist(const std::string &path);
		static bool is_directory(const std::string &dir_path);
		static void get_dir_all_file(const char *path, std::vector<std::string> &file_vector);
		static void get_dir_all(const char *path, std::vector<std::string> &file_vector);
		static void get_dir_single(const char *path, std::vector<std::string> &file_vector, std::vector<int> &file_type_vector);
		static time_t get_file_create_timer(const char *path);
	};
}

#endif  // USTD_PATH_H_
