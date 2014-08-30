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

require 'cgi'

require 'open-uri'
require 'net/http'

require 'faraday'
require 'faraday_middleware'

require 'mechanize'

require 'ipaddr'

# require 'resolv'
# require 'resolv-replace'

module Apollo
	module Fetcher
		class BaseFetcher
			def self.get_fake_headers(url)
				ip = IPAddr.new(rand(2**32), Socket::AF_INET).to_s

				return {
					"X-Forwarded-For" => ip
				}
			end

			def self.fetch_old(url, options = {})
				begin
					uri = URI.parse(url.to_s)
				rescue Exception => e
					puts "EXCEPTION: BaseFetcher::fetch() - Unable to fetch: '#{e.to_s}'"
					return nil
				end

				# See https://github.com/lostisland/faraday
				conn = Faraday.new(:url => url) do |faraday|
					# faraday.request  :url_encoded             # form-encode POST params
					# faraday.response :logger                  # log requests to STDOUT
					faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
				end

				# Make request
				begin
					res = conn.get(uri) do |request|
						request.headers = BaseFetcher.get_fake_headers(uri)
					end
				rescue Exception => e
					puts "EXCEPTION: BaseFetcher::fetch() - Unable to fetch: '#{e.to_s}'"
					return nil
				end

				# Return result
				return res
			end	

			def self.fetch(url, options = {})
				begin
					uri = URI.parse(url.to_s)
				rescue Exception => e
					puts "EXCEPTION: BaseFetcher::fetch() - Unable to fetch: '#{e.to_s}'"
					return nil
				end

				agent = Mechanize.new do |agent|
  					agent.user_agent = 'Apollo Crawler'
  				end

				page = agent.get(uri)

				res = {
					:status => page.code,
					:headers => page.header.to_hash,
					:body => page.content
				}

				return res
			end			
		end # class BaseFetcher
	end # module Fetcher
end # module Apollo
