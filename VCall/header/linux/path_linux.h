#pragma once

#ifndef USTD_LINUX_PATH_H_
#define USTD_LINUX_PATH_H_

#include <string>
#include <vector>

std::string linux_get_app_path();
bool linux_is_file_exist(const std::string &file_path);
bool linux_create_directory(const char* path);
std::string linux_get_path_root(const std::string &dir_path);
std::string linux_get_directory_name(const std::string &dir_path_name);
std::string linux_get_filename(const std::string &file_path);
std::string linux_get_full_path(const std::string &file_path);
long long linux_get_file_size(const std::string &file_path);
std::string linux_get_no_ext(const std::string &file_path);
std::string linux_get_file_ext(const std::string &file_path);
bool linux_remove_file(const std::string &file_path);
bool linux_is_directory_exist(const std::string &path);
bool linux_is_directory(const std::string &dir_path);
void linux_get_dir_all_file(const char *path, std::vector<std::string> &file_vector);
void linux_get_dir_all(const char *path, std::vector<std::string> &file_vector);
void linux_get_dir_single(const char *path, std::vector<std::string> &file_vector, std::vector<int> &file_type_vector);
long linux_get_file_create_timer(const char *path);

#endif  // USTD_LINUX_PATH_H_
