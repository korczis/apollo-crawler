# Copyright, 2013, by Tomas Korcak. <korczis@gmail.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

# See http://stackoverflow.com/questions/6233124/where-to-place-access-config-file-in-gem

require 'yaml'

require File.join(File.dirname(__FILE__), 'lib')

module Apollo
	module RbConfig
		############################################################
		# Program - basic settings
		############################################################
		
		# Directory for storing apollo-crawler data
		PROGRAM_DIRECTORY = File.expand_path("~/.apollo-crawler")

		PROGRAM_PLUGINS_DIRECTORY = File.join(PROGRAM_DIRECTORY, "plugins")
		PROGRAM_TEMP_DIRECTORY = File.join(PROGRAM_DIRECTORY, "tmp")

		# Basic PROGRAM_DIRECTORY structure, lazy created
		PROGRAM_DIRECTORIES = [
			PROGRAM_DIRECTORY,
			PROGRAM_PLUGINS_DIRECTORY,
			PROGRAM_TEMP_DIRECTORY
		]



		PROGRAM_CONFIG_PATH = File.join(RbConfig::PROGRAM_DIRECTORY, "config.rb")



		############################################################
		# Caches - caches implementations
		############################################################
		CACHES_DIR = File.join(File.dirname(__FILE__), "caches")



		############################################################
		# Cache implementation used for chaching pages retreived
		############################################################
		#
		# Filesystem backend
		# CACHE_CLASS = Apollo::Cache::FilesystemCache
		#
		# Memcached - expects localhost:11211
		# CACHE_CLASS = Apollo::Cache::MemcachedCache
		#
		# Pure naive ruby in-memory implementation
		# CACHE_CLASS = Apollo::Cache::MemoryCache
		#
		# Null caching - no caching at all
		# CACHE_CLASS = Apollo::Cache::NullCache

		CACHE_CLASS_OPTIONS_MONGO = {
			:host => 'apollo-crawler.no-ip.org', 
			:port => 27017, 
			:pool_size => 5, 
			:pool_timeout => 5,
			:db => 'apollo-crawler',
			:collection => 'fetched_docs'
		}

		CACHE_CLASS_OPTIONS_SQLITE3 = {
			:db => 'apollo-crawler-db',
			:collection => 'fetched_docs'
		}

		# Used caching mechanism by default
		CACHE_CLASS = Apollo::Cache::MemcachedCache
		CACHE_CLASS_OPTIONS = nil

		############################################################
		# Crawlers - Built-in out-of box working crawlers
		############################################################
		CRAWLERS_DIR = File.join(File.dirname(__FILE__), "crawler")
		
		# Template used for generated crawlers
		CRAWLER_TEMPLATE_NAME = "crawler_template.trb"

		# Path of template
		CRAWLER_TEMPLATE_PATH = File.join(CRAWLERS_DIR, CRAWLER_TEMPLATE_NAME)



		############################################################
		# Fetchers - used for fetching documents
		############################################################
		FETCHERS_DIR = File.join(File.dirname(__FILE__), "fetcher")
		
		DEFAULT_FETCHER = Apollo::Fetcher::SmartFetcher


		############################################################
		# Formatters - used for formatting crawled documents results
		############################################################
		FORMATTERS_DIR = File.join(File.dirname(__FILE__), "formatter")

		# Default formatter if no other specified
		DEFAULT_FORMATTER = Apollo::Formatter::JsonFormatter



		############################################################
		# Loggers - used for formatting output messages
		############################################################
		DEFAULT_LOGGER = Apollo::Logger::ConsoleLogger
	end # Config
end
