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

require "net/http"
require "uri"

require File.join(File.dirname(__FILE__), "../model/models.rb")

module Apollo
	module Scheduler
		class BaseScheduler
			def self.schedule(url, crawler=nil, opts={})
				queued_url = Apollo::Model::QueuedUrl.where(:url => url).first

				if queued_url.nil? == false
					return queued_url
				end

				uri = URI.parse(url)
				domain = Apollo::Model::Domain.where(:name => uri.hostname).first
				if(domain.nil?)
					domain = Apollo::Model::Domain.new(:name => uri.hostname)
					domain.save
				end
					
				res = Apollo::Model::QueuedUrl.new(:url => url, :state => :queued, :crawler_name => crawler.to_s)
				res.save
				return res				
			end
		end # class BaseScheduler
	end # module Scheduler
end # module Apollo
