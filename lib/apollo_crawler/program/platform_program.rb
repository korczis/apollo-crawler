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
require 'csv'

require 'mongoid'

require File.join(File.dirname(__FILE__), '..', 'version')

require File.join(File.dirname(__FILE__),'base_program')

require File.join(File.dirname(__FILE__),'../scheduler/schedulers')

module Apollo
	# Apollo Crawler Base Directory
	APOLLO_PLATFORM_BASE_DIR = File.join(File.dirname(__FILE__), "..")

	class PlatformProgram < BaseProgram
		# Load default config
		require File.join(File.dirname(__FILE__), "..", "config")

		DEFAULT_OPTIONS = {
			:version => nil
		}

		# Initializer - Constructor
		def initialize
			super
			
			self.options.merge!(DEFAULT_OPTIONS)
		end

		def init_options()
			self.optparser = OptionParser.new do | opts |
				opts.banner = "Usage: apollo-platform [OPTIONS]"

				opts.separator ""
      			opts.separator "Specific options:"

				# This displays the help screen, all programs are
				# assumed to have this option.
				opts.on('-h', '--help', 'Display this screen') do
					self.options[:show_help] = true
				end

				opts.on('-e', '--environment [NAME]', "Environment used, default '#{options[:env]}'") do |name|
					self.options[:env] = name
				end

				opts.on('-d', '--daemon', 'Run Apollo Platform daemon') do
					self.options[:daemon] = true
				end

				opts.on('-v', '--verbose', 'Enable verbose output') do
					self.options[:verbose] = true
				end

				opts.on('-V', '--version', 'Show version info') do
					self.options[:version] = true
				end
			end
		end

		def enqueue_crawlers_urls(amqp, crawlers=Apollo::Crawler::BaseCrawler.subclasses, opts={})
			crawlers.each do |crawler|
				i = crawler.new
				Apollo::Scheduler::BaseScheduler::schedule(i.url, crawler)
			end	
		end

		def init_crawlers(amqp, opts={})
			crawlers = []
			crawlers << Apollo::Agent::CrawlerAgent.new(amqp, self.options)
		end

		def init_domainers(amqp, opts={})
			domainers = []
			domainers << Apollo::Agent::DomainerAgent.new(amqp, self.options)
		end

		def init_fetchers(amqp, opts={})
			fetchers = []
			fetchers << Apollo::Agent::FetcherAgent.new(amqp, self.options)

			# TODO: This should not be here!
			enqueue_crawlers_urls(amqp, Apollo::Crawler::BaseCrawler.subclasses, opts)
		end

		def init_agents(amqp, opts={})
			puts "Initializing agents"

			init_crawlers(amqp, opts)
			init_domainers(amqp, opts)
			init_fetchers(amqp, opts)	
		end

		def init_domains(opts={})
			path = File.join(File.dirname(__FILE__), "../../../tmp/top-1m.csv")
			puts "#{path}"
			if(File.exists?(path) == false)
				return 0
			end

			Thread::new {
				Apollo::Helper::Mongo::csv_bulk_insert(path, Apollo::Model::Domain, 1000, false) do |row|
					rank = row[0].to_i
					name = row[1]

					res = {
						:rank => rank, 
						:name => name
					}

					res
				end
			}
		end

		def init_program(args)
			res = super(args)
			return res unless res.nil?

			init_agents(self.amqp, self.options)
			return nil
		end

		def process_options(args)
			if(self.options[:version])
				puts Apollo::VERSION
				return 0
			end

			if(self.options[:show_help])
				puts optparser
				return 0
			end

			# Return nil, it means program can freely continue.
			return nil
		end

		def requeue_fetching_urls(opts={})
			urls = Apollo::Model::QueuedUrl.where(:state => :fetching)
			urls.each do |url|
				puts "Requeing '#{url.inspect}'" if opts[:verbose]

				url.state = :queued
				url.save
			end
		end

		# Run Program
		def run(args = ARGV)
			res = super(args)
			return res unless res.nil?

			init_domains()

			requeue_fetching_urls(self.options)

			# Here we start
			# if(ARGV.length < 1)
			# 	puts optparser
			# 	return 0
			# end

			res_code = 0
			if(self.options[:daemon])
				planner = Apollo::Planner::SmartPlanner.new(self.amqp, self.mongo, self.options)
				res_code = planner.run(self.options)
			end

			return request_exit(res_code)
		end
	end
end
