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

require File.join(File.dirname(__FILE__), '../crawler/crawlers')

require 'nokogiri'

module Apollo
	module Agent
		class CrawlerAgent < BaseAgent
			attr_accessor :declarations

			def initialize(amqp, opts={})
				if(opts[:verbose])
					puts "Initializing crawler agent..."
				end

				# Declarations
				channel = amqp.create_channel
				self.declarations = Apollo::Agent.declare_entities(channel, opts)# Binding
				
				# Binding
				queue = self.declarations[:queues]["crawler.queue"]
				exchange = self.declarations[:exchanges]["crawler"]

				queue.bind(exchange).subscribe do |delivery_info, metadata, payload|
					msg = JSON.parse(payload)

					request = msg['request']
					response = msg['response']
					url = request["url"]

					puts "CrawlerAgent: Received - '#{url}', metadata #{metadata.inspect}" if opts[:verbose]

					doc = Nokogiri::HTML(response['body'])
					crawler = request['crawler_name'].constantize.new
					data = crawler.extract_data(doc)
					links = crawler.extract_links(doc)

					# puts crawler.to_s
					# puts res.inspect

					if(metadata[:reply_to] != nil)
						x = self.declarations[:exchanges][metadata[:reply_to]]

						msg = {
							:request => request,
							:response => response,
							:data => data,
							:links => links
						}

						x.publish(msg.to_json)
					end
				end
			end
		end # class CrawlerAgent
	end # module Agent
end # module Apollo
