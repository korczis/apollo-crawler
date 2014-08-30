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
require 'dalli'

module Apollo
	module Cache
		class MemcachedCache < BaseCache
			@cache = nil

			def initialize(options = {})
				super(options)
				
				@cache = Dalli::Client.new()
			end

			def get(key)
				@cache.get(key)
			end

			# Get value associated with key from cache
			def try_get(key, *args)
				res = get(key)

				# Not found, Create, cache and return
				if res.nil? && block_given?
					res = yield args

					self.set(key, res)
				end
				
				return res
			end

			# Set value associated with key 
			# Return cached value
			def set(key, value)
				@cache.set(key, value)
				return key
			end
		end # class MemcachedCache
	end # module Cache
end # module Apollo
