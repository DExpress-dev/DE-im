#include "path.h"
#include <stdio.h>
#include <string.h>
#include <fcntl.h>
#include <list>
#include "path.h"

#if defined(_WIN32)

	#include <windows.h>
	#include <Mmsystem.h>
	#include <time.h>
	#include "windows/timer_windows.h"
	#include "windows/file_windows.h"
	#include "windows/path_windows.h"
	#include <io.h>

	#define gettimeofday(a, b) gettimeofday(a, b)
	#define path_separator "/"
	#define get_file_no(a) _fileno(a)
	#define sysc_write_file(a) _commit(a)

	#define harq_remove_file(a) windows_remove_file(a)
	#define harq_create_file(a) windows_create_file(a)
	#define harq_open_file(a) windows_open_file(a)
	#define harq_set_postion(a, b) windows_set_postion(a, b)
	#define harq_write_file(a, b, c) windows_write_file(a, b, c)
	#define harq_close_file(a) windows_close_file(a)
#else

	#include <unistd.h>
	#include <sys/time.h>
	#include "linux/file_linux.h"
	#include "linux/path_linux.h"

	#define gettimeofday(a, b) gettimeofday(a, b)
	const std::string path_separator = "/";
	#define get_file_no(a) ::fileno(a)
	#define sysc_write_file(a) ::fsync(a)

	#define harq_remove_file(a) linux_remove_file(a)
	#define harq_create_file(a) linux_create_file(a)
	#define harq_open_file(a) linux_open_file(a)
	#define harq_set_postion(a, b) linux_set_postion(a, b)
	#define harq_write_file(a, b, c) linux_write_file(a, b, c)
	#define harq_close_file(a) linux_close_file(a)
#endif

#include "write_log.h"

#define BEIJINGTIME 8
#define DAY        (60 * 60 * 24)
#define YEARFIRST  2001
#define YEARSTART  (365 * (YEARFIRST - 1970) + 8)
#define YEAR400    (365 * 4 * 100 + (4 * (100 / 4 - 1) + 1))
#define YEAR100    (365*100 + (100/4 - 1))
#define YEAR004    (365*4 + 1)
#define YEAR001    365

namespace ustd
{
	namespace log
	{
		struct logger_entry
		{
			time_t time;
			int level;
			char *data;
			int size;
		};

		write_log::write_log(bool show_log)
		{
			show_log_ = show_log;
			level_ = LOG_TYPE_TRACE;
			session_ = "";
			directory_ = "";
			file_name_ = "";
			file_path_ = "";
		}

		write_log::~write_log()
		{
			if(file_handle_ != 0)
			{
				harq_close_file(file_handle_);
				file_handle_ = 0;
			}
		}

		std::string write_log::get_sysytem_time()
		{
			struct timeval tv;
			long sec = 0, usec = 0;
			int yy = 0, mm = 0, dd = 0, hh = 0, mi = 0, ss = 0, ms = 0;
			int ad = 0;
			int y400 = 0, y100 = 0, y004 = 0, y001 = 0;
			int m[12] = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31};
			int i;

			memset(&tv, 0, sizeof(timeval));
			gettimeofday(&tv, NULL);
			sec = tv.tv_sec;
			usec = tv.tv_usec;
			sec = sec + (60 * 60) * BEIJINGTIME;
			ad = (int)(sec/DAY);
			ad = ad - YEARSTART;
			y400 = ad/YEAR400;
			y100 = (ad - y400 * YEAR400) / YEAR100;
			y004 = (ad - y400 * YEAR400 - y100 * YEAR100) / YEAR004;
			y001 = (ad - y400 * YEAR400 - y100 * YEAR100 - y004 * YEAR004) / YEAR001;
			yy = y400 * 4 * 100 + y100 * 100 + y004 * 4 + y001 * 1 + YEARFIRST;
			dd = (ad - y400 * YEAR400 - y100 * YEAR100 - y004 * YEAR004) % YEAR001;

			if(0 == yy % 1000)
			{
				if(0 == (yy / 1000) %4 )
				{
					m[1] = 29;
				}
			}
			else
			{
				if(0 == yy % 4)
				{
					m[1] = 29;
				}
			}

			for(i = 1; i <= 12; i++)
			{
				if(dd - m[i] < 0)
				{
					break;
				}
				else
				{
					dd = dd -m[i];
				}
			}
			mm = i;
			hh = sec / (60 * 60) % 24;
			mi = (int)(sec / 60 - sec / (60 * 60) * 60);
			ss = (int)(sec - sec / 60 * 60);
			ms = (int)usec;

			char time_buffer[1024] = {0};

			sprintf(time_buffer, "%d-%02d-%02d %02d:%02d:%02d.%06d", yy, mm, dd, hh, mi, ss, ms);
			
			return time_buffer;
		}

		void write_log::check_path()
		{
			char local_system_time_string[32] = {0};
			time_t t_now_string = time(nullptr);
			strftime(local_system_time_string, 32, "%Y-%m-%d", localtime(&t_now_string));

			if(strcmp(local_system_time_string, file_name_.c_str()) != 0)
			{
				file_name_ = local_system_time_string;
				file_path_ += directory_;
				file_path_ += path_separator;
				file_path_ += file_name_;

				if(file_handle_ != 0)
				{
					harq_close_file(file_handle_);
				}

				//判断文件是否存在;
				if (ustd::path::is_file_exist(file_path_))
				{
					file_handle_ = harq_open_file(file_path_);
				}
				else
				{
					file_handle_ = harq_create_file(file_path_);
				}

				//检测日志文件
				check_files();
			}
		}

		bool write_log::init(const std::string &session, const std::string &path, const int &level)
		{
			directory_ = ustd::path::get_app_path() + path_separator + path;
			if (!ustd::path::create_directory(directory_.c_str()))
			{
				printf("create dir failed");
				return false;
			}

			char local_system_time_string[32] = {0};
			time_t t_now_string = time(nullptr);
			strftime(local_system_time_string, 32, "%Y-%m-%d", localtime(&t_now_string));

			session_ = session;
			level_ = level;
			file_name_ = local_system_time_string;
			file_path_ = directory_ + path_separator + file_name_;

			//检测日志文件
			check_files();

			if (ustd::path::is_file_exist(file_path_))
			{
				file_handle_ = harq_open_file(file_path_);
			}
			else
			{
				file_handle_ = harq_create_file(file_path_);
			}
			
			if(file_handle_ == 0)
			{
				printf("open log file fail log_file_path=%s", file_path_.c_str());
				return false;
			}
			return true;
		}

		void write_log::log_v(const int &level, const char *format, va_list args)
		{
			if(level < level_)
			{
				return;
			}
			check_path();

			const int MAX_LEN = 1024 * 10;
			char log_text[MAX_LEN] = {0};
			int pos = 0;

			std::string current_timer = get_sysytem_time();
			pos = sprintf(log_text, "[%s]", current_timer.c_str());

			//level
			pos += sprintf(((char *)log_text)+pos, "[%s]", log_level_desc_styled(level).c_str());

			//text
			pos += vsprintf(((char *)log_text) + pos, format, args);
			sprintf(((char *)log_text)+pos, "\n");

			if(file_handle_ == 0)
			{
				printf(log_text);
				return;
			}

			size_t len = strlen(log_text);
			harq_write_file(file_handle_, log_text, len);
			printf(log_text);
		}

		void write_log::log_i(const int &level, const char *format, va_list args)
		{
			if(level < level_)
			{
				return;
			}
			check_path();

			const int MAX_LEN = 1024 * 10;
			char log_text[MAX_LEN] = {0};
			int pos = 0;

			std::string current_timer = get_sysytem_time();
			pos = sprintf(log_text, "[%s]", current_timer.c_str());

			//level
			pos += sprintf(((char *)log_text)+pos, "[%s]", log_level_desc_styled(level).c_str());

			//text
			pos += vsprintf(((char *)log_text) + pos, format, args);
			sprintf(((char *)log_text)+pos, "\n");

			if(file_handle_ == 0)
			{
				printf(log_text);
				return;
			}
			harq_write_file(file_handle_, log_text, strlen(log_text));
		}

		void write_log::write_log3(const int &level, const char *format, ...)
		{
			if(level < level_)
			{
				return;
			}

			va_list args;
			va_start(args, format);
			if(show_log_)
			{
				this->log_v(level, format, args);
			}
			else
			{
				this->log_i(level, format, args);
			}
			va_end(args);
		}

		void write_log::trace(const char *format, ...)
		{
			if(LOG_TYPE_TRACE < level_)
			{
				return;
			}

			va_list args;
			va_start(args, format);
			this->log_v(LOG_TYPE_TRACE, format, args);
			va_end(args);
		}

		void write_log::debug(const char *format, ...)
		{
			if(LOG_TYPE_DEBUG < level_)
			{
				return;
			}

			va_list args;
			va_start(args, format);
			this->log_v(LOG_TYPE_DEBUG, format, args);
			va_end(args);
		}

		void write_log::info(const char *format, ...)
		{
			if(LOG_TYPE_INFO < level_)
			{
				return;
			}

			va_list args;
			va_start(args, format);
			this->log_v(LOG_TYPE_INFO, format, args);
			va_end(args);
		}

		void write_log::warn(const char *format, ...)
		{
			if(LOG_TYPE_WARNING < level_)
			{
				return;
			}

			va_list args;
			va_start(args, format);
			this->log_v(LOG_TYPE_WARNING, format, args);
			va_end(args);
		}

		void write_log::error(const char *format, ...)
		{
			if(LOG_TYPE_ERROR < level_)
			{
				return;
			}

			va_list args;
			va_start(args, format);
			this->log_v(LOG_TYPE_ERROR, format, args);
			va_end(args);
		}

		void write_log::get_files(std::vector<std::string> file_vector)
		{
			dir_files_list_.clear();
			for (size_t i = 0; i < file_vector.size(); i++)
			{
				std::string file_path = file_vector[i];
				time_t file_create_timer = ustd::path::get_file_create_timer(file_path.c_str());

				std::shared_ptr<dir_files_record> curr_file(new dir_files_record);
				curr_file->file_path_ = file_path;
				curr_file->time_create_ = file_create_timer;

				dir_files_list_.push_back(curr_file);
			}
		}

		void write_log::check_files()
		{
			//得到目录下的文件列表
			std::vector<std::string> file_vector_;
			file_vector_.clear();
			ustd::path::get_dir_all_file(directory_.c_str(), file_vector_);
			if (file_vector_.size() > MAX_LOG_FILES)
			{
				get_files(file_vector_);

				//检测文件是否已经超过数量;
				delete_dir_files();
			}
		}

		bool comp(std::shared_ptr<dir_files_record> x, std::shared_ptr<dir_files_record> y) 
		{
			return x->time_create_ > y->time_create_;
		}

		void write_log::delete_dir_files()
		{
			dir_files_list_.sort(comp);

			int postion = 0;
			for(auto iter = dir_files_list_.begin(); iter != dir_files_list_.end();)
			{
				postion++;
				if(postion > MAX_LOG_FILES)
				{
					//删除文件;
					std::shared_ptr<dir_files_record> curr_file = *iter;
					harq_remove_file(curr_file->file_path_.c_str());
					iter = dir_files_list_.erase(iter);
				}
				else
				{
					iter++;
				}
			}
		}

		std::string log_level_desc(const int &level)
		{
			switch(level)
			{
			case LOG_TYPE_TRACE:
				return "TRACE";
				break;
			case LOG_TYPE_DEBUG:
					return "DEBUG";
					break;
			case LOG_TYPE_INFO:
					return "INFO";
					break;
			case LOG_TYPE_WARNING:
					return "WARNING";
					break;
			case LOG_TYPE_ERROR:
					return "ERROR";
					break;
			default:
				return "TRACE";
			}
		}

		std::string log_level_desc_styled(const int &level)
		{
			switch(level)
			{
			case LOG_TYPE_TRACE:
				return "TRACE";
				break;
			case LOG_TYPE_DEBUG:
					return "DEBUG";
					break;
			case LOG_TYPE_INFO:
					return "INFO ";
					break;
			case LOG_TYPE_WARNING:
					return "WARN ";
					break;
			case LOG_TYPE_ERROR:
					return "ERROR";
					break;
			default:
				return "TRACE";
			}
		}

	} 
} 

