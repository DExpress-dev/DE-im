#pragma once

#ifndef USTD_LINUX_FILE_H_
#define USTD_LINUX_FILE_H_

#include <string>
#include <vector>

int linux_create_file(const std::string &file_path);
int linux_open_file(const std::string &file_path);
void linux_set_postion(int file_handle, int64_t postion);
ssize_t linux_write_file(int file_handle, char *buffer, size_t size);
int linux_read_file(int file_handle, char *buffer, size_t size);
int linux_postion_read_file(int file_handle, int64_t postion, char *buffer, size_t size);
void linux_close_file(int file_handle);  
size_t linux_postion_write_file(int file_handle, int64_t postion, char *buffer, size_t size);

#endif  // USTD_LINUX_FILE_H_
