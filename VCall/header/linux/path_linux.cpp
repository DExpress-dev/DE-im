#include "path_linux.h"

#include <iostream>
#include <stdio.h>
#include <cstring>
#include <cstdio>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <dirent.h>
#include <fcntl.h>

std::string linux_get_app_path()
{
	char file_path_getcwd[BUFSIZ] = {0};
	memset(file_path_getcwd, 0, BUFSIZ);
	getcwd(file_path_getcwd, BUFSIZ);
	std::string tmp_app_path(file_path_getcwd);
	return tmp_app_path;
}

bool linux_create_directory(const char* path)
{
    ssize_t beginCmpPath;
	int endCmpPath;
    ssize_t pathLen = strlen(path);
	char currentPath[128] = {0};

	//相对路径
	if('/' != path[0] && '\\' != path[0])
	{
		//获取当前路径
		#if defined(_WIN32)

			char *file_path_getcwd;
			file_path_getcwd = getcwd(NULL, BUFSIZ);
			if (nullptr == file_path_getcwd)
			{
				return "";
			}

			std::string tmp_app_path(file_path_getcwd);
			free(file_path_getcwd);

			memcpy(currentPath, tmp_app_path.c_str(), tmp_app_path.length());
		#else

			getcwd(currentPath, sizeof(currentPath));
		#endif

		strcat(currentPath, "/");
		beginCmpPath = strlen(currentPath);
		strcat(currentPath, path);
		if(path[pathLen] != '/' && path[pathLen] != '\\')
		{
			strcat(currentPath, "/");
		}
		endCmpPath = strlen(currentPath);
	}
	else
	{
		//绝对路径
		int pathLen = strlen(path);
		strcpy(currentPath, path);
		if(path[pathLen] != '/' && path[pathLen] != '\\')
		{
			strcat(currentPath, "/");
		}
		beginCmpPath = 1;
		endCmpPath = strlen(currentPath);
	}

	//创建各级目录
	for(int i = beginCmpPath; i < endCmpPath ; i++ )
	{
		if('/' == currentPath[i] || '\\' == currentPath[i])
		{
			currentPath[i] = '\0';
			if(access((char*)(currentPath), 0) != 0)
			{
				if(mkdir((char*)currentPath, 0755) == -1)
				{
					return false;
				}
			}
			currentPath[i] = '/';
		}
	}
	return true;
}

std::string linux_get_no_ext(const std::string &file_path)
{
	if("" == file_path)
		return "";

	std::string strPath = file_path;
	for (int nPos = 0; nPos <= (int)strPath.size() - 1; nPos++)
	{
		char cChar = strPath[nPos];
		if ('.' == cChar)
			return strPath.substr(0, nPos);
	}
	return strPath;
}

bool linux_is_file_exist(const std::string &file_path)
{
	if("" == file_path)
		return false;

	return (access(file_path.c_str(), F_OK) == 0);
}

std::string linux_get_directory_name(const std::string &dir_path_name)
{
	if("" == dir_path_name)
		return "";

	std::string tmp_path = dir_path_name;
	for (int nPos = (int)tmp_path.size()-1; nPos >= 0; --nPos)
	{
		char cChar = tmp_path[nPos];
		if ('\\' == cChar || '/' == cChar)
			return tmp_path.substr(0, nPos + 1);
	}
	return dir_path_name;
}

bool linux_is_directory(const std::string &dir_path)
{
	if ("" == dir_path)
		return false;

	DIR *dir;
	dir = opendir(dir_path.c_str());
	if (dir == NULL)
	{
		return false;
	}
	closedir(dir);
	return true;
}

void linux_get_dir_all_file(const char *path, std::vector<std::string> &file_vector)
{
	DIR *dir;
	struct dirent *ptr;
	file_vector.clear();

	if ((dir = opendir(path)) == NULL)
		return;

	while ((ptr = readdir(dir)) != NULL)
	{
		if(strcmp(ptr->d_name,".")==0 || strcmp(ptr->d_name,"..") == 0)
		{
			continue;
		}

		else if(ptr->d_type == DT_REG)		//常规文件
		{
			char file_all_path[1024] = {0};
			sprintf(file_all_path, "%s/%s", path, ptr->d_name);
			std::string tmp_file_name(file_all_path);
			file_vector.push_back(tmp_file_name);
		}
		else if(ptr->d_type == DT_LNK)		//符号链接
		{
			char file_all_path[1024] = {0};
			sprintf(file_all_path, "%s/%s", path, ptr->d_name);
			std::string tmp_file_name(file_all_path);
			file_vector.push_back(tmp_file_name);
		}
	}
	closedir(dir);
}

void linux_get_dir_all(const char *path, std::vector<std::string> &file_vector)
{
	DIR *dir;
	struct dirent *ptr;

	if ((dir = opendir(path)) == NULL)
		return;

	while ((ptr = readdir(dir)) != NULL)
	{
		if(strcmp(ptr->d_name,".")==0 || strcmp(ptr->d_name,"..") == 0)
		{
			continue;
		}
		else if(ptr->d_type == DT_REG)		//常规文件
		{
			char file_all_path[1024] = {0};
			sprintf(file_all_path, "%s/%s", path, ptr->d_name);
			std::string tmp_file_name(file_all_path);
			file_vector.push_back(tmp_file_name);
		}
		else if(ptr->d_type == DT_LNK)		//符号链接
		{
			char file_all_path[1024] = {0};
			sprintf(file_all_path, "%s/%s", path, ptr->d_name);
			std::string tmp_file_name(file_all_path);
			file_vector.push_back(tmp_file_name);
		}
		else if(ptr->d_type == DT_DIR)		//目录
		{
			char dir_all_path[1024] = {0};
			sprintf(dir_all_path, "%s/%s", path, ptr->d_name);
			std::string tmp_dir_name(dir_all_path);
			linux_get_dir_all(dir_all_path, file_vector);
		}
	}
	closedir(dir);
}

void linux_get_dir_single(const char *path, std::vector<std::string> &file_vector, std::vector<int> &file_type_vector)
{
	DIR *dir;
	struct dirent *ptr;

	if ((dir = opendir(path)) == NULL)
		return;

	while ((ptr = readdir(dir)) != NULL)
	{
		if(strcmp(ptr->d_name,".")==0 || strcmp(ptr->d_name,"..") == 0)
		{
			continue;
		}
		else if(ptr->d_type == DT_REG)		//常规文件
		{
			char file_all_path[1024] = {0};
			sprintf(file_all_path, "%s/%s", path, ptr->d_name);
			std::string tmp_file_name(file_all_path);
			file_vector.push_back(tmp_file_name);
			file_type_vector.push_back(1);
		}
		else if(ptr->d_type == DT_LNK)		//符号链接
		{
			char file_all_path[1024] = {0};
			sprintf(file_all_path, "%s/%s", path, ptr->d_name);
			std::string tmp_file_name(file_all_path);
			file_vector.push_back(tmp_file_name);
			file_type_vector.push_back(1);
		}
		else if(ptr->d_type == DT_DIR)		//目录
		{
			char file_all_path[1024] = {0};
			sprintf(file_all_path, "%s/%s", path, ptr->d_name);
			std::string tmp_file_name(file_all_path);
			file_vector.push_back(tmp_file_name);
			file_type_vector.push_back(0);
		}
	}
	closedir(dir);
}

bool linux_is_directory_exist(const std::string &path)
{
	if("" == path)
		return false;

	try
	{
		DIR *dir;
		if((dir = opendir(path.c_str())) == NULL)
		{
			return false;
		}
		closedir(dir);
		return true;
	}
	catch(...)
	{
		return true;
	}
}

std::string linux_get_filename(const std::string &file_path)
{
	if("" == file_path)
		return "";

	std::string strPath = file_path;
	for (int nPos = (int)strPath.size() - 1; nPos >= 0; --nPos)
	{
		char cChar = strPath[nPos];
		if ('\\' == cChar || '/' == cChar)
			return strPath.substr(nPos+1);
	}
	return strPath;
}

std::string linux_get_full_path(const std::string &file_path)
{
	std::string directory;
	const size_t last_slash_idx = file_path.rfind('\\');
	if (std::string::npos != last_slash_idx)
	{
		directory = file_path.substr(0, last_slash_idx);
	}
	else
	{
		const size_t last_slash_idx_2 = file_path.rfind('/');
		if (std::string::npos != last_slash_idx_2)
		{
			directory = file_path.substr(0, last_slash_idx_2);
		}
	}
	return directory;
}

long long linux_get_file_size(const std::string &file_path)
{
	if(!linux_is_file_exist(file_path))
		return -1;

	int read_fd = open(file_path.c_str(), O_RDWR);
	if(-1 == read_fd)
		return -1;

	long long file_size = lseek(read_fd, 0, SEEK_END);
	close(read_fd);
	return file_size;
}

std::string linux_get_file_ext(const std::string &file_path)
{
	std::size_t found = file_path.find(".");
	if(found != std::string::npos)
	{
		std::string ext = file_path.substr(found + 1, file_path.length() - found);
		return ext;
	}
	return "";
}

bool linux_remove_file(const std::string &file_path)
{
	if (linux_is_file_exist(file_path))
	{
		if (0 == remove(file_path.c_str()))
			return true;
		else
			return false;
	}
	return true;
}

long linux_get_file_create_timer(const char *path)
{
	FILE * fp;
	int fd;
	struct stat buf;

	fp = fopen(path, "r");
	if (fp == NULL)
	{
		return 0;
	}

	fd = fileno(fp);
	fstat(fd, &buf);
	
	long create_time = buf.st_ctime;
	fclose(fp);

	return create_time;
}
