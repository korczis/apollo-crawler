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

require File.join(File.dirname(__FILE__),'base_planner') 

require File.join(File.dirname(__FILE__),'../model/models.rb') 

require File.join(File.dirname(__FILE__),'../agent/exchanges.rb') 

require File.join(File.dirname(__FILE__),'../scheduler/schedulers')

require 'nokogiri'

module Apollo
	module Planner
		class SmartPlanner < BasePlanner
			attr_accessor :amqp
			attr_accessor :mongo
			attr_accessor :declarations

			def initialize(amqp=nil, mongo=nil, opts={})
				self.amqp = amqp
				self.mongo = mongo

				# Declarations
				channel = amqp.create_channel
				# channel.prefetch(1)
				self.declarations = Apollo::Agent.declare_entities(channel, opts)

				# Bindings
				declarations[:queues]["planner.fetched.queue"].bind(declarations[:exchanges]["planner.fetched"]).subscribe do |delivery_info, metadata, payload|
					msg = JSON.parse(payload)
					puts "#{msg.inspect}" if opts[:verbose]

					puts "REQ: #{msg['request']}" if opts[:verbose]
					puts "RESP: #{msg['response']}" if opts[:verbose]

					request = msg['request']
					response = msg['response']

					doc = Apollo::Model::QueuedUrl.find(request["_id"])
					doc.update_attributes(msg['request'])
					doc.state = :fetched
					doc.save

					doc = Apollo::Model::RawDocument.where(:url => request['url']).first
					if doc
						if doc.sha_hash != response['sha_hash']
							puts "Removing old cached version of '#{request['url']}'" if opts[:verbose]
							
							doc.destroy
							doc = nil
						else
							puts "Using cached version of '#{request['url']}'" if opts[:verbose]
						end
					else
						doc = Apollo::Model::RawDocument.where(:sha_hash => response['sha_hash']).first
						if(doc.nil? == false)
							puts "Same as #{doc.inspect}"
						end
					end

					if(doc.nil?)
						doc = Apollo::Model::RawDocument.new(response).save

						# Publish
						declarations[:exchanges]["crawler"].publish(msg.to_json, :reply_to => "planner.crawled")
					end
				end

				declarations[:queues]["planner.domained.queue"].bind(declarations[:exchanges]["planner.domained"]).subscribe do |delivery_info, metadata, payload|
					msg = JSON.parse(payload)

					puts "DOMAINED !!!"
				end

				declarations[:queues]["planner.crawled.queue"].bind(declarations[:exchanges]["planner.crawled"]).subscribe do |delivery_info, metadata, payload|
					msg = JSON.parse(payload)

					# puts "Crawled - #{msg.inspect}"

					request = msg['request']
					response = msg['response']
					data = msg['data']
					links = msg['links']
					links = [] if links.nil?

					data_hash = Digest::SHA256.new.update(data).hexdigest
					puts "#{data_hash}"

					links.each do |url|
						link = url['link']
						
						Apollo::Scheduler::BaseScheduler::schedule(link, request['crawler_name'])
					end

					# puts JSON.pretty_generate(data)
					# puts JSON.pretty_generate(links)
				end
			end

			def get_url_count(state, opts={})
				Apollo::Model::QueuedUrl.where({:state => state}).count
			end

			def fetch_url(url, opts={})
				if(opts[:verbose])
					puts "AMQP fetching '#{url.inspect}'"
				end

				# Publish
				declarations[:exchanges]["fetcher"].publish(url.to_json, :reply_to => "planner.fetched")
			end

			def get_next_url(opts={})
				tmp = Apollo::Model::QueuedUrl.where({:state => :queued}).order_by(:created_at.asc)
				res = tmp.find_and_modify({ "$set" => { state: :fetching }}, new: true)
				return res
			end

			def fetch_queued_urls(opts={})
				fetching_count = Apollo::Model::QueuedUrl.where({:state => :fetching}).count
				
				if(fetching_count > 4)
					puts "Fetching too many URLs. Slowing down for a while ..."
					return
				end

				while get_url_count(:fetching) < 4
					url = get_next_url(opts)
					puts "SmartPlanner::fetch_queued_urls() - Queueing: #{url.inspect}"
					fetch_url(url, opts)
				end
			end

			def run(opts={})
				request_exit = false
				
				while request_exit == false
					fetch_queued_urls(opts)
					sleep 1
				end

				return 0
			end
		end # class SmartPlanner
	end # module Planner
end # module Apollo
