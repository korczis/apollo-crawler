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

require "open-uri"
require "nokogiri"

module Apollo
	module Crawler
		class BaseCrawler
			

			@backlog = nil
			@visited = nil

			def initialize
				@backlog = []
				@visited = []
			end

			def self.name_re()
				return /crawler$/
			end

			# Name of the crawler
			def name
				return "Crawler Base" 
			end

			def url
				return nil
			end

			def self.fetch(url)
				RbConfig::DEFAULT_FETCHER.fetch(url)
			end

			def self.try_get_url(root, url)
				begin
					return URI.join(root, url)
				rescue
					return nil
				end
			end

			def self.try_get_doc(root, url)
				doc = BaseCrawler.try_get_url(root, url)
				
				# TODO: Set experition header
				return {
					:doc => doc,
					:url => url
				}
			end

			# - (0) Figure out URL
			# - (1) Extract Data
			# - (2) Extract Links
			# - (3) Go to (0) eventually
			def etl(url=nil, opts={}, &block)
				# Look for passed URL use default instead and fail if it is not valid
				if(url.nil? || url.empty?)
					url = self.url
				end

				# TODO: Be more agressive, use assert, it is clients responsibility!
				if(url.nil?)
					return nil
				end

				enqueue_url(url)

				# Counter of processed documents (pages)
				docs_processed = 0

				res = []
				# TODO: Respect limit of documents/urls processed
				while(@backlog.empty? == false)
					url = @backlog.shift

					# puts "Processing '#{url}'"
					doc = self.process_url(url)
					
					# Increase counter of processed documents
					docs_processed = docs_processed + 1

					@visited << url

					# Process document if was successfuly retreived
					if(!doc.nil?)
						# TODO: Use log4r and log it only on info level
						if block_given?
							yield doc
						end

						# Add document to queue of results
						res << doc

						enqueue_url(doc[:links].map(){ |l| l[:link] }) if doc[:links]
					end

					# Break if limit of documents to processed was reached
					break if opts[:doc_limit] && docs_processed >= opts[:doc_limit]
				end

				# Return processed document
				return res
			end

			def url_processed?(url)
				return @backlog.include?(url) || @visited.include?(url)
			end

			def enqueue_url(url)
				urls = []
				return urls if url.nil?
				# We support both - list of urls or single url
				if(url.kind_of?(Array))
					urls = urls.concat(url)
				else
					urls << url
				end

				urls.each do |u|
					if(url_processed?(u) == false)
						@backlog << u
					end
				end
			end

			def process_url(url)
				doc = self.fetch_document(url)
				if(doc.nil?)
					return nil
				end

				# Try extract data from document
				data = self.extract_data(doc)

				# Try extract links for another documents 
				links = self.extract_links(doc)
				
				# TODO: Make configurable if links extracted from doc should be printed
				# puts links.inspect

				# Format ETL result
				res = { 
					:crawler => self.class.name,
					:data => data,
					:links => links
				}

				return res
			end

			def self.create_metadoc(url, doc)
				body = doc[:body].encode('UTF-8', {:invalid => :replace, :undef => :replace, :replace => '?'})
				
				return {
					'url' => url,
					'doc' => body,
					'hash' => Digest::SHA256.new.update(body).hexdigest,
					'created_at' => Time.now.utc,
					'expires_at' => nil,
					'version' => 0
				}
			end

			# Fetch document
			def fetch_document(url)
				# TODO: Refactor following idiom
				if(url == nil)
					url = self.url
				end

				if(url.nil?)
					return nil
				end

				url = url.to_s

				# TODO: Use some (custom-made) low-level HTTTP Protocol cache - just for sure
				cache = Apollo::Cache::Factory.instance.construct
				metadoc = cache.try_get(url) do
					max_attempts = 3
					attempt_no = 0
					success = false
					
					doc = nil
					while(attempt_no < max_attempts && success == false) do
						begin
							doc = BaseCrawler.fetch(url)
							success = true
						rescue Exception => e
							puts "EXCEPTION: Unable to fetch '#{url}', reason: '#{e.to_s}'"
							sleep 1

							attempt_no = attempt_no + 1
							success = false
						end
					end

					# Create metadata
					BaseCrawler.create_metadoc(url, doc)
				end

				# TODO: Encapsulate and make more robust => invalid hostname, timeouts and so
				return Nokogiri::HTML(metadoc['doc'])
			end

			# Extracts data from document
			def extract_data(doc)
				res = []
				return res
			end

			# Extract links to another documents from this document
			def extract_links(doc)
				res = []
				return res
			end
		end # class BaseCrawler
	end # module Crawler
end # module Apollo