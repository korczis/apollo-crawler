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

# TODO: Make this work - DRY!
# require File.join(File.dirname(__FILE__), 'apollo_crawler/lib')

# Config First
require File.join(File.dirname(__FILE__), 'apollo_crawler/env')

# Agents
require File.join(File.dirname(__FILE__), 'apollo_crawler/agent/agents')

# Caches
require File.join(File.dirname(__FILE__), 'apollo_crawler/cache/caches')

# Crawlers
require File.join(File.dirname(__FILE__), 'apollo_crawler/crawler/crawlers')

# Fetchers
require File.join(File.dirname(__FILE__), 'apollo_crawler/fetcher/fetchers')

# Formatters
require File.join(File.dirname(__FILE__), 'apollo_crawler/formatter/formatters')

# Helpers
require File.join(File.dirname(__FILE__), 'apollo_crawler/helper/helpers')

# Loggers
require File.join(File.dirname(__FILE__), 'apollo_crawler/logger/loggers')

# Models
require File.join(File.dirname(__FILE__), 'apollo_crawler/model/models')

# Planner
require File.join(File.dirname(__FILE__), 'apollo_crawler/planner/planners')

# Program
require File.join(File.dirname(__FILE__), 'apollo_crawler/program/programs')

# Scheduler
require File.join(File.dirname(__FILE__), 'apollo_crawler/scheduler/schedulers')

# Stores
require File.join(File.dirname(__FILE__), 'apollo_crawler/store/stores')
