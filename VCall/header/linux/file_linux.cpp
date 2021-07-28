#include "file_linux.h"

#include <iostream>
#include <stdio.h>
#include <cstring>
#include <cstdio>

#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

#include <string.h>
#include <unistd.h>

int linux_create_file(const std::string &file_path)
{
	int file_handle = open(file_path.c_str(), O_RDWR | O_CREAT | O_APPEND, S_IRUSR | S_IWUSR);
	return file_handle;
}

int linux_open_file(const std::string &file_path)
{
	int file_handle = open(file_path.c_str(), O_RDWR | O_CREAT | O_APPEND, S_IRUSR | S_IWUSR);
	return file_handle;
}

ssize_t linux_write_file(int file_handle, char *buffer, size_t size)
{
	if(-1 == file_handle)
		return 0;

	return write(file_handle, buffer, size);
}

int linux_read_file(int file_handle, char *buffer, size_t size)
{
	if (-1 == file_handle)
		return 0;

	return read(file_handle, buffer, size);
}

int linux_postion_read_file(int file_handle, int64_t postion, char *buffer, size_t size)
{
	if (-1 == file_handle)
		return 0;

	lseek(file_handle, postion, SEEK_SET);
	return read(file_handle, buffer, size);
}

void linux_set_postion(int file_handle, int64_t postion)
{
	if (-1 == file_handle)
		return;

	lseek(file_handle, postion, SEEK_SET);
	return;
}

void linux_close_file(int file_handle)
{
	if(-1 == file_handle)
		return;

	close(file_handle);
}

size_t linux_postion_write_file(int file_handle, int64_t postion, char *buffer, size_t size)
{
	if (-1 == file_handle)
		return 0;

	lseek(file_handle, postion, SEEK_SET);
	return write(file_handle, buffer, size);
}