#ifndef _WRITE_LOG_H_
#define _WRITE_LOG_H_

#include <string>
#include <stdio.h>
#include <limits.h>
#include <stdarg.h>
#include <stdlib.h>
#include <memory>
#include <list>
#include <vector>

const int LOG_TYPE_BASE 	= 0;
const int LOG_TYPE_TRACE 	= LOG_TYPE_BASE + 1;
const int LOG_TYPE_DEBUG 	= LOG_TYPE_BASE + 2;
const int LOG_TYPE_INFO 	= LOG_TYPE_BASE + 3;
const int LOG_TYPE_WARNING	= LOG_TYPE_BASE + 4;
const int LOG_TYPE_ERROR 	= LOG_TYPE_BASE + 5;
const int MAX_LOG_FILES		= 3;

#if defined(_WIN32)

	#include <windows.h>
	#include <Mmsystem.h>
	#include <time.h>
	#include "windows/timer_windows.h"
	#include "windows/file_windows.h"
	#include <io.h>
	
	#define harq_file_handle HANDLE
#else

	#include <unistd.h>
	#include <sys/time.h>
	#include "linux/file_linux.h"

	#define harq_file_handle int
#endif

namespace ustd
{
	namespace log
	{
		struct dir_files_record
		{
			time_t time_create_;
			std::string file_path_;
		};
		typedef std::list<std::shared_ptr<dir_files_record>> dir_files_list;

		class write_log
		{
		public:
			bool show_log_ = false;
			harq_file_handle file_handle_ = 0;
			int fd_ = -1;
			write_log(bool show_log = true);
			~write_log(void);

			bool init(const std::string &session, const std::string &path, const int &level);
			void log_v(const int &level, const char *format, va_list args);
			void log_i(const int &level, const char *format, va_list args);
			void trace(const char *format, ...);
			void debug(const char *format, ...);
			void info(const char *format, ...);
			void warn(const char *format, ...);
			void error(const char *format, ...);
			std::string get_sysytem_time();

		private:
			std::string session_ = "";
			std::string directory_ = "";
			std::string file_name_ = "";
			std::string file_path_ = "";
			int level_ = 1;
			void check_path();

		private:
			//检测日志数量是否已经超过了上限;
			dir_files_list dir_files_list_;
			void check_files();
			void get_files(std::vector<std::string> file_vector);
			void delete_dir_files();

		public:
			void write_log3(const int &level, const char *format, ...);

		};

		std::string log_level_desc(const int &level);
		std::string log_level_desc_styled(const int &level);
	} 
} 

#endif //_WRITE_LOG_H_

