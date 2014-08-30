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

module Apollo
	module Agent
		def self.declare_queues(channel, opts={})
			if(opts[:verbose])
				puts "Declaring AMQP Queues"
			end

			# Queues
			queues = {}
			queues["crawler.queue"] = channel.queue("crawler.queue", :auto_delete => false, :durable => true)
			queues["domainer.queue"] = channel.queue("domainer.queue", :auto_delete => false, :durable => true)
			queues["fetcher.queue"] = channel.queue("fetcher.queue", :auto_delete => false, :durable => true)
			queues["planner.crawled.queue"] = channel.queue("planner.crawled.queue", :auto_delete => false, :durable => true)
			queues["planner.domained.queue"] = channel.queue("planner.domained.queue", :auto_delete => false, :durable => true)
			queues["planner.fetched.queue"] = channel.queue("planner.fetched.queue", :auto_delete => false, :durable => true)

			return queues
		end

		def self.declare_exchanges(channel, opts={})
			if(opts[:verbose])
				puts "Declaring AMQP Exchanges"
			end
			
			# Exchanges
			exchanges = {}
			exchanges["crawler"] = channel.direct("crawler", :auto_delete => false, :durable => true)
			exchanges["domainer"] = channel.direct("domainer", :auto_delete => false, :durable => true)
			exchanges["fetcher"] = channel.direct("fetcher", :auto_delete => false, :durable => true)
			exchanges["planner.crawled"] = channel.direct("planner.crawled", :auto_delete => false, :durable => true)
			exchanges["planner.domained"] = channel.direct("planner.domained", :auto_delete => false, :durable => true)
			exchanges["planner.fetched"] = channel.direct("planner.fetched", :auto_delete => false, :durable => true)
			
			return exchanges
		end

		def self.declare_entities(channel, opts={})
			exchanges = self.declare_exchanges(channel, opts)
			queues = self.declare_queues(channel, opts)

			# Compose res
			res = {
				:exchanges => exchanges,
				:queues => queues				
			}

			return res
		end
	end
end