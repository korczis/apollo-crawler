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

require File.join(File.dirname(__FILE__), 'exchanges')
require File.join(File.dirname(__FILE__), 'base_agent')

require File.join(File.dirname(__FILE__), '../fetcher/fetchers')

require 'amqp'
require 'amqp/extensions/rabbitmq'

require 'digest/sha1'
require 'thread'

module Apollo
	module Agent
		class FetcherAgent < BaseAgent
			THREAD_POOL_SIZE = 1

			attr_accessor :fetcher
			attr_accessor :declarations
			attr_accessor :mutex

			def initialize(amqp, opts={})
				self.fetcher = Apollo::Fetcher::SmartFetcher.new

				if(opts[:verbose])
					puts "Initializing fetcher agent..."
				end

				# Declarations
				channel = amqp.create_channel
				channel.prefetch(THREAD_POOL_SIZE)
				
				# Binding (Default)
				self.declarations = Apollo::Agent.declare_entities(channel, opts)
				queue = declarations[:queues]["fetcher.queue"]

				# AMQP contexts for threads
				contexts = []
				(0...THREAD_POOL_SIZE).each do |i|
					puts "FetcherAgent::initialize() - Creating context #{i}" if opts[:verbose]
				end

				# AMQP contexts mutex/lock
				self.mutex = Mutex.new()

				exchange = self.declarations[:exchanges]["fetcher"]

				queue.bind(exchange).subscribe(:ack => true) do |delivery_info, metadata, payload|		
					# There can be troubles with concurency, please see https://groups.google.com/forum/?fromgroups=#!topic/ruby-amqp/aO9GPu-jxuE
					queued_url = JSON.parse(payload)
					url = queued_url["url"]

					puts "FetcherAgent: Received - '#{url}', metadata #{metadata.inspect}" if opts[:verbose]
					self.mutex.synchronize {
						puts "FetcherAgent: Acking - '#{delivery_info.delivery_tag}'" if opts[:verbose]
						channel.basic_ack(delivery_info.delivery_tag, true)
					}

					begin
						doc = Apollo::Fetcher::SmartFetcher::fetch(url)
						doc = process_fetched_doc(queued_url, doc, metadata, opts)
						
						if(metadata && metadata[:reply_to])
							puts "Replying to '#{metadata[:reply_to]}'"
							send_response_msg(metadata[:reply_to], queued_url, doc)
						end

					rescue Exception => e
						puts "EXCEPTION: FetcherAgent::initialize() - Unable to fetch '#{url}', reason: '#{e.to_s}'"
					end

					doc
				end
			end

			def process_fetched_doc(queued_url, doc, metadata, opts={})
				url = queued_url["url"]

				res = Apollo::Model::RawDocument.new
				res.headers = doc[:headers]
				res.body = doc[:body]
				res.sha_hash = Digest::SHA1.hexdigest(doc[:body])
				res.status = doc[:status]
				res.url = url

				return res
			end

			def format_response_msg(queued_url, doc)
				return {
					:request => queued_url,
					:response => doc
				}
			end

			def send_response_msg(dest, queued_url, doc)
				if(dest != nil)							
					msg = format_response_msg(queued_url, doc)

					self.mutex.synchronize {
						exchange = self.declarations[:exchanges][dest]
						exchange.publish(msg.to_json)
					}
				end
			end
		end # class FetcherAgent
	end # module Agent
end # module Apollo
