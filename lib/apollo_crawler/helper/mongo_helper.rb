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

require 'mongo'
require 'mongoid'

require 'csv'

module Apollo
	module Helper
		module Mongo
			def self.connect(conn, opts={})
				if(opts[:verbose])
					puts "MongoDB connecting - '#{conn.inspect}"
				end

				res = ::Mongo::Connection.new(conn['host'])

				if(opts[:verbose])
					puts "MongoDB connected: #{res.inspect}"
				end

				return res
			end

			def self.csv_bulk_insert(path, model, bulk_size, validate=false, &block)
				batch = []
				
				CSV.foreach(path) do |row|
					res = nil
					if block_given?
						res = yield row
					end

					if res.nil? == false
						if(!validate || model.where(res).length == 0)
							batch << res
						end
					end

					if((batch.length % bulk_size) == 0)
						# puts "Inserting batch '#{batch.inspect}'"
						
						model.collection.insert(batch)
						batch.clear
					end
				end

				if batch.empty? == false
					model.collection.insert(batch)
					batch.clear
				end
			end

		end # Mongo
	end # module Helper
end # module Apollo
