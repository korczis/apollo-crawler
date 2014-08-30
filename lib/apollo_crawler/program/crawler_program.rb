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

require 'json'

require "thor"

require "open-uri"
require "nokogiri"

require "pp"
require "optparse"

require 'active_support'
require 'active_support/inflector'

require 'terminal-table'

require 'eventmachine'
require 'em-http'

require 'fileutils'

require File.join(File.dirname(__FILE__), '..', 'version') 

# require File.join(File.dirname(__FILE__), 'config/crawler')
# puts Apollo::CrawlerProgramConfig

require File.join(File.dirname(__FILE__),'base_program') 

module Apollo
	# Apollo Crawler Base Directory
	APOLLO_CRAWLER_BASE_DIR = File.join(File.dirname(__FILE__), "..")

	# Modules enabled
	APOLLO_CRAWLER_MODULES = [
		"agent",
		"cache",
		"crawler",
		"formatter"
	]

	class CrawlerProgram < BaseProgram
		# Load default config
		require File.join(File.dirname(__FILE__), "..", "config")

		# This hash will hold all of the options
		# parsed from the command-line by OptionParser.
		@options = nil
		@optparser = nil

		# Initializer - Constructor
		def initialize
			super
			
			@options = {}

			at_exit { 
				at_exit_handler
			}
		end

		def self.get_modules_paths(modules = APOLLO_CRAWLER_MODULES)
			res = modules.map do |name|
				Dir[File.join(APOLLO_CRAWLER_BASE_DIR, name, "*.rb")].each do |path|
					path
				end
			end

			res.flatten.sort
		end

		def self.register_modules(modules = APOLLO_CRAWLER_MODULES)
			get_modules_paths(modules).each do |file| 
				# puts "Adding module '#{file}'"
				require file
			end
		end

		# Show tabular data in form of CLI table
		def self.console_table(headings, rows)
			rows = rows.map do |o| 
				i = o.new

				res = []
				headings.each do |h|
					res << i.instance_eval(h)
				end
				res
			end

			table = Terminal::Table.new :headings => headings, :rows => rows
			puts table
		end

		# Initialize command-line options
		def init_options()
			@options[:env] = Apollo::ENV	

			@options[:doc_limit] = nil
			@options[:verbose] = false
			@options[:version] = nil
			
			@options[:cache_dirs] = [
				RbConfig::CACHES_DIR
			]
			
			@options[:crawler_dirs] = [
				RbConfig::CRAWLERS_DIR
			]
			
			@options[:formatter_dirs] = [
				RbConfig::FORMATTERS_DIR
			]

			@options[:generate_crawler] = nil
		end

		def init_options_parser()
			@optparser = OptionParser.new do | opts |
				opts.banner = "Usage: apollo-crawler [OPTIONS] CRAWLER_NAME [START_URL]"

				opts.separator ""
      			opts.separator "Specific options:"

				# This displays the help screen, all programs are
				# assumed to have this option.
				opts.on('-h', '--help', 'Display this screen') do
					@options[:show_help] = true
				end

				opts.on('-a', '--all', 'Run all crawlers') do
					@options[:run_all] = true
				end	

				opts.on('-e', '--environment [NAME]', "Environment used, default '#{@options[:env]}'") do |name|
					@options[:env] = name
				end

				opts.on('-f', '--format [NAME]', "Formatter used") do |name|
					@options[:formatter] = name
				end

				opts.on('-g', '--generate [NAME]', "Generate scaffold for new crawler") do |name|
					@options[:generate_crawler] = name
				end

				opts.on('-i', '--include [PATH]', 'Include additional crawler or crawler directory') do |path|
					@options[:crawler_dirs] << path

					init_additional_crawlers([path])
				end

				opts.on('-n', '--doc-limit [NUM]', 'Limit count of documents to be processed') do |count|
					@options[:doc_limit] = count.to_i
				end

				opts.on('-v', '--verbose', 'Enable verbose output') do
					@options[:verbose] = true
				end

				opts.on('-V', '--version', 'Show version info') do
					@options[:version] = true
				end

				opts.on('-l', '--list-crawlers', 'List of crawlers') do
					@options[:list_crawlers] = true
				end

				opts.on(nil, '--list-formatters', 'List of formatters available') do
					@options[:list_formatters] = true
				end			

				# opts.on('-q', '--query [QUERY]', 'Query crawler database for phrase') do |query|
				# 	@options[:query] = query
				# end	

				opts.on('-s', '--silent', 'Silent mode - do not print processed document') do
					@options[:silent] = true
				end	
			end
		end

		# Parse the options passed to command-line
		def parse_options(args = ARGV)
			# Parse the command-line. Remember there are two forms
			# of the parse method. The 'parse' method simply parses
			# ARGV, while the 'parse!' method parses ARGV and removes
			# any options found there, as well as any parameters for
			# the options. What's left is the list of files to resize.
			@optparser.parse!(args)
		end

		def process_options(args)
			if(@options[:version])
				puts Apollo::VERSION
				return 0
			end

			if(@options[:show_help])
				puts @optparser
				return 0
			end

			if(@options[:generate_crawler])
				name = @options[:generate_crawler]
				url = args.length > 0 ? args[0] : nil
				matcher = args.length > 1 ? args[1] : nil
				
				return self.generate_crawler(name, url, matcher)
			end

			if(@options[:list_formatters])
				objs = Apollo::Formatter::BaseFormatter.subclasses
				CrawlerProgram.console_table(['name', 'self.class'], objs)
				return 0
			end

			if(@options[:list_crawlers])
				objs = Apollo::Crawler::BaseCrawler.subclasses
				CrawlerProgram.console_table(['name', 'self.class'], objs)
				return 0
			end

			return nil
		end

		# Load global options first
		# Merge it with local options (if they exists)
		def load_config_file(config = RbConfig::PROGRAM_CONFIG_PATH)
			if(File.exists?(config))
				if(@options[:verbose])
					puts "Loading config '#{config}'"
				end
				
				require config
			else
				if(@options[:verbose])
					# TODO: Add support for initial rake task generation
					#          Something like this:
					#          rake config:init # Initializes config files with
					#            their defaults (if not exists already)        
					puts "Default config does not exist, skipping - '#{config}'"
				end
			end
		end

		def generate_crawler(name, url = nil, matcher = nil, options = @options)
			name = name.titleize.gsub(" ", "")

			if(@options[:verbose])
				puts "Generating new crawler '#{name}'"
			end

			template_path = RbConfig::CRAWLER_TEMPLATE_PATH
			puts template_path
			if(File.exists?(template_path) == false)
				puts "Template file '#{template_path}' does not exists!"
				return -1
			end

			if(options[:verbose])
				puts "Using template '#{template_path}'"
			end

			unless(options[:silent])
				dest_path = File.join(Dir.pwd, "#{name.underscore}.rb")
			end

			url = url ? url : "http://some-url-here"
			matcher = matcher ? matcher : "//a"
			
			placeholders = {
				"CRAWLER_CLASS_NAME" => name,
				"CRAWLER_NAME" => name.titleize,
				"CRAWLER_URL"  => url,
				"CRAWLER_MATCHER" => matcher
			}

			puts "Generating crawler '#{name.titleize}', class: '#{name}', path: '#{dest_path}'"

			File.open(template_path, 'r') do |tmpl|
				File.open(dest_path, 'w') do |crawler|  
					while line = tmpl.gets  
						#puts line
						placeholders.each do |k, v|
							line.gsub!(k, v)
						end
						
						crawler.puts line
					end  
				end
			end  

			return 0
		end

		def get_crawlers_by_name(crawlers, crawler_classes = Apollo::Crawler::BaseCrawler.subclasses)
			res = []
			crawlers.each do |crawler|
				next if crawler.nil?

				crawler_classes.each do |klass|
					next if klass.nil?

					crawler_name = crawler.to_s.split('::').last.downcase
					klass_name = klass.to_s.split('::').last.downcase.gsub("crawler", "")

					# puts "#{crawler_name} => #{klass_name}"

					if crawler_name == klass_name || crawler_name == "#{klass_name}crawler"
						res << klass
						break
					end
				end
			end
			res
		end

		def run_crawlers(crawlers, args, options = @options)
			crawlers.each do |crawler|
				if(options[:verbose])
					puts "Running '#{crawler}'"
				end

				opts = {
					:doc_limit => options[:doc_limit]
				}

				# Run crawlers
				instance = crawler.new

				if(args.nil? || args.empty?)
					args = instance.url
				end

				res = instance.etl(args, opts) do | docs |
					process_docs_handler(docs, options, Apollo::Formatter::JsonFormatter.new)
				end
			end

			return 0
		end

		# Get crawlers passd to cmd-line
		def get_crawlers(args, options = @options)
			crawlers = []
			if(args.length > 0)
				crawlers << args.shift
			end

			if(options[:run_all])
				crawlers = @crawlers.keys
			end

			return crawlers
		end

		def init_program_directory(base_dir = RbConfig::PROGRAM_DIRECTORY, dirs = RbConfig::PROGRAM_DIRECTORIES, options = @options)			
			dirs.each do |dir|
				if(File.directory?(dir) == false)
					if(options[:verbose])
						puts "Creating '#{dir}'"
					end

					FileUtils.mkpath(dir)
				end
			end

			init_user_config_file(File.join(File.dirname(__FILE__), 'config_user.trb'), File.join(base_dir, 'config.rb'))			
		end

		def init_user_config_file(config_path, dest_path, options = @options)
			# Create user config file
			if(File.exists?(config_path) && File.exists?(dest_path) == false)
				if(options[:verbose])
					puts "Creating user config file '#{config_path}' => '#{dest_path}'"
				end

				FileUtils.cp(config_path, dest_path)
			end
		end

		def init_additional_crawlers(dirs)
			# puts "Initializing aditional crawlers ..."
			dirs.each do |dir|
				if(@options[:verbose])
					puts "Registering additional crawler dir '#{dir}'"
				end

				Dir.glob("#{dir}/*.rb").each do |f| 
					if(@options[:verbose])
						puts "Registering crawler '#{f}'"
					end
					require f
				end
			end
		end

		# Init program
		def init_program(args)
			init_options()
			init_options_parser()

			CrawlerProgram.register_modules()

			parse_options(args)

			init_program_directory(RbConfig::PROGRAM_DIRECTORY, RbConfig::PROGRAM_DIRECTORIES)

			load_config_file()

			res = process_options(args)
			if res != nil
				return res
			end

			return nil
		end

		def run_query(query, options = {})
			if(options[:verbose])
				puts "Investigating query '#{query}'"
			end

			return 0
		end

		# Run Program
		def run(args = ARGV)
			res_code = init_program(args)

			if res_code.nil? == false
				return request_exit(res_code)
			end

			if(@options[:verbose])
				puts "Running environment '#{@options[:env]}'"
			end

			# Look for query
			if(@options[:query])
				res_code = run_query(@options[:query], @options)
				return request_exit(res_code)
			end

			# Parse remaining arguments as crawlers
			crawler_names = get_crawlers(args)
			if(crawler_names.nil? || crawler_names.empty?)
				puts @optparser
				return request_exit(0)
			end	

			# Get crawlers by their names
			crawlers = get_crawlers_by_name(crawler_names, Apollo::Crawler::BaseCrawler.subclasses)
			if(crawlers.nil? || crawlers.empty?)
				puts @optparser
				return request_exit(0)
			end	

			res_code = run_crawlers(crawlers, args, @options)
			return request_exit(res_code)
		end

		def request_exit(code = 0)
			begin
				exit(0)
			rescue SystemExit => e
				# puts "rescued a SystemExit exception, reason: '#{e.to_s}'"
			end

			return code
		end

		def process_docs_handler(docs, options = options, formatter)
			if(docs.nil?)
				return docs
			end

			if(docs.kind_of?(Array) == false)
				docs = [docs]
			end

			if options[:silent] != true
				docs.each do |doc|
					puts formatter.format(doc)
				end
			end

			return docs
		end

		# At Exit handler
		def at_exit_handler()
			# if(@options[:verbose])
			# 	puts "Running at_exit_handler" 
			# end

			# TODO: Flush caches
			# TODO: End gracefully

			# Force exit event machine
			# EventMachine.stop
		end
	end
end
