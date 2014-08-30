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

require 'yaml'

require File.join(File.dirname(__FILE__), "../model/models.rb")

module Apollo
	class BaseProgram
		CONFIG_DIR = File.join(Apollo::BASE_DIR, "config")
		
		DEFAULT_OPTIONS = {
			:env => Apollo::ENV,
			:verbose => false
		}

		attr_accessor :config
		attr_accessor :options
		attr_accessor :optparser

		attr_accessor :amqp
		attr_accessor :mongo

		def initialize
			self.config = {}
			self.options = DEFAULT_OPTIONS
			self.optparser = nil

			self.amqp = nil
			self.mongo = nil
		end

		def self.get_config_path(config)
			return File.join(CONFIG_DIR, "#{config}.yml")
		end

		def load_configs(dir = CONFIG_DIR, options = DEFAULT_OPTIONS)
			Dir[File.join(dir, "**/*.yml")].each do |c|
				puts "Loading config #{c}" if options[:verbose]
				self.load_config_file(c, options)
			end

			return self.config
		end

		def load_config_file(config_file, options = DEFAULT_OPTIONS)
			return nil unless File.exists?(config_file)

			config_name = File.basename(config_file.downcase, ".yml")

			res = YAML.load(File.read(config_file))
			return nil unless res

			res = {config_name => res[options[:env]]}
			self.config.merge! res
			
			if(options[:verbose])
				puts "Loaded config '#{config_file}' => #{res[config_name]}"
			end

			return res[config_name]
		end

		def load_config(config_name, options = DEFAULT_OPTIONS)
			path = BaseProgram.get_config_path(config_name)
			return load_config_file(path, options)
		end

		def self.require_files(files = [])
			Dir.glob(files).each do |file|
				require file
			end
		end

		# Parse the options passed to command-line
		def parse_options(args = ARGV)
			res = []

			# Parse the command-line. Remember there are two forms
			# of the parse method. The 'parse' method simply parses
			# ARGV, while the 'parse!' method parses ARGV and removes
			# any options found there, as well as any parameters for
			# the options. What's left is the list of files to resize.
			begin
				optparser.parse!(args)
			rescue Exception => e
				return nil
			end

			return res
		end

		def process_options(args)
			return nil
		end

		def init_options()
			return nil
		end

		def init_amqp()
			conn_opts = self.config["amqp"]
			if(conn_opts)
				self.amqp = Apollo::Helper::Amqp::connect(conn_opts, self.options)
			end

			return self.amqp
		end

		def init_mongo()
			conn_opts = self.config["mongo"]
			if(conn_opts)
				self.mongo = Apollo::Helper::Mongo::connect(conn_opts, self.options)

				# Init Mongoid
				path = File.join(Apollo::BASE_DIR, "config/mongoid.yml")
				Mongoid.load!(path, @options[:env])
			end

			return self.mongo
		end

		def init_seeds_crawlers(opts={})
			objs = Apollo::Crawler::BaseCrawler.subclasses
			objs.each do |o|
				crawler = Apollo::Model::Crawler.new
				i = o.new
				crawler.name = i.name
				crawler.class_name = o.to_s
				
				res = Apollo::Model::Crawler.where(class_name: crawler.class_name)
				# puts "RES: '#{res.inspect}'"
				if(res.nil? || res.count < 1)
					crawler.save
					if(opts[:verbose])
						puts "Adding new crawler - '#{crawler.inspect}'"
					end
				else
					if(opts[:verbose])
						puts "Using crawler - '#{res[0].inspect}'"
					end
				end
			end
		end

		def init_seeds(opts={})
			init_seeds_crawlers(opts)
		end

		# Init program
		def init_program(args)
			res = nil
			res = init_options()

			begin
				res = parse_options(args)
			rescue Exception => e
				puts "Unable to parse options"
				return res unless res.nil?
			end

			res = process_options(args)
			return res unless res.nil?

			confs = load_configs(BaseProgram::CONFIG_DIR, @options)
			puts "Loaded configs => #{confs.inspect}" if @options[:verbose]

			# Init Mongo Connection
			init_mongo()

			# Init AMQP
			init_amqp()

			# Init Seed data
			init_seeds(@options)

			return nil
		end

		# Run Program
		def run(args = ARGV)
			res = init_program(args)
			return res unless res.nil?

			puts "Running environment '#{@options[:env]}'" if @options[:verbose]
		end

		def request_exit(code = 0)
			puts "Exiting app"
			begin
				exit(code)
			rescue SystemExit => e
				# puts "rescued a SystemExit exception, reason: '#{e.to_s}'"
			end

			return code
		end
	end # class BaseProgram
end # module Apollo