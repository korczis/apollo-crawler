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

require 'amqp'
require 'amqp/extensions/rabbitmq'
require 'bunny'
require 'thread'

module Apollo
	module Helper
		module Amqp
			def self.connect(conn, opts={})
				res = nil

				if(opts[:verbose])
					puts "AMQP Connecting - #{conn.inspect}"
				end

				res = Bunny.new(:host => conn['host'], :user => conn['username'], :password => conn['password'], :vhost => conn['vhost'], :port => conn['port'])
				res.start

				sleep(0.001) until res
				if(opts[:verbose])
					puts "AMQP connected - #{res.inspect}"
				end

				return res
			end
		end # Amqp
	end # module Helper
end # module Apollo
