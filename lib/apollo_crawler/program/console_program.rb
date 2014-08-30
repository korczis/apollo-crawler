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

require File.join(File.dirname(__FILE__), 'base_program') 

module Apollo
	# Apollo Crawler Base Directory
	APOLLO_CONSOLE_BASE_DIR = File.join(File.dirname(__FILE__), "..")

	class ConsoleProgram < BaseProgram
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
		end

		# Initialize command-line options
		def init_options()
			@options[:env] = Apollo::ENV	

			@options[:verbose] = false
			@options[:version] = nil
		end

		def init_options_parser()
			@optparser = OptionParser.new do | opts |
				opts.banner = "Usage: apollo-console [OPTIONS]"

				opts.separator ""
      			opts.separator "Specific options:"

				# This displays the help screen, all programs are
				# assumed to have this option.
				opts.on('-h', '--help', 'Display this screen') do
					@options[:show_help] = true
				end

				opts.on('-e', '--environment [NAME]', "Environment used, default '#{@options[:env]}'") do |name|
					@options[:env] = name
				end

				opts.on('-v', '--verbose', 'Enable verbose output') do
					@options[:verbose] = true
				end

				opts.on('-V', '--version', 'Show version info') do
					@options[:version] = true
				end

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

			return nil
		end


		# Init program
		def init_program(args)
			init_options()
			init_options_parser()


			parse_options(args)

			res = process_options(args)
			if res != nil
				return res
			end

			return nil
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

			# if(ARGV.length < 1)
			# 	puts @optparser
			# 	return 0
			# end

			# Here we start

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
	end
end
