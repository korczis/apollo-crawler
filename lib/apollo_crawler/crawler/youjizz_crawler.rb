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
	module Crawler
		class YoujizzCrawler < BaseCrawler
			@@MATCHER_ITEM = "//span[@id = 'miniatura']/span/a"

			def name()
				return "Youjizz"
			end

			def url()
				return "http://www.youjizz.com/"
			end

			def extract_data(doc)
				res = doc.xpath(@@MATCHER_ITEM).map { | node |
					link = BaseCrawler.try_get_url(self.url, node['href']).to_s
					next if link.nil?

					{ 
						:text => link,
						:link => link
					}
				}
			end

			def extract_links(doc)
				res = doc.xpath("//div[@id = 'pagination']/a").map { | node |
					link = BaseCrawler.try_get_url(self.url, node['href']).to_s
					next if link.nil?

					{ 
						:link => link
					}
				}
			end
		end
	end # Crawler
end # Apollo

