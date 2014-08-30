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

require File.join(File.dirname(__FILE__), 'base_cache') 

require 'mongo'

module Apollo
	module Cache
		class MongoCache < BaseCache
			@@DEFAULT_OPTIONS = {
				:host => 'localhost', 
				:port => 27017, 
				:pool_size => 5, 
				:pool_timeout => 5,
				:db => 'apollo-crawler',
				:collection => 'cached_docs'
			}

			def initialize(options = @@DEFAULT_OPTIONS)
				super(options)
				
				opts = @@DEFAULT_OPTIONS.merge(options)
				
				@mongo_client = Mongo::MongoClient.new(opts[:host], opts[:port], :pool_size => opts[:pool_size], :pool_timeout => opts[:pool_timeout])
				@db = @mongo_client[opts[:db]]
				@coll = @db[opts[:collection]]
			end

			def get(key)
				@coll.find({:url => key})
			end

			# Get value associated with key from cache
			def try_get(key, *args)
				key = key.to_s

				res = get(key)

				# Not found, Create, cache and return
				if res.nil? || res.count < 1 && block_given?
					res = yield args
					return self.set(key, res)
				end

				return res.to_a[0]
			end

			# Set value associated with key 
			# Return cached value
			def set(key, value)
				@coll.insert(value)
				return value
			end
		end # MongoCache
	end # Cache
end # Apollo
