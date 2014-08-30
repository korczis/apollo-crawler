require 'capistrano'

require "rubygems"
require "bundler/setup"
require "bundler/capistrano"

# RVM integration
require "rvm/capistrano"

# Target ruby version
set :rvm_ruby_string, '2.0.0'

set :domain, "apollo-crawler.no-ip.org"
set :application, "apollo_platform"
# set :deploy_to, File.join(File.expand_path("~"), "/apps/#{application}")
set :deploy_to, "/home/ubuntu/apps/#{application}"

ssh_options[:keys] = [File.join(ENV["HOME"], ".ssh", "key-webs.pem")]

set :user, "ubuntu"
set :use_sudo, false

set :scm, :git
set :repository,  "https://github.com/korczis/apollo-crawler.git"
set :branch, 'master'
set :git_shallow_clone, 1

role :web, domain
role :app, domain
role :db,  domain, :primary => true

set :deploy_via, :remote_cache

namespace :deploy do
  def remote_cmd(cmd)
     run "cd #{deploy_to}/current && #{cmd}"
  end

  task :start, :roles => [:web, :app] do
    puts "Starting.."
    remote_cmd "./bin/apollo-platform -V"
  end
 
  task :stop, :roles => [:web, :app] do
    puts "Stopping.."
  end

  task :status, :roles => [:web, :app] do
    puts "Statusing.."
  end
 
  task :restart, :roles => [:web, :app] do
    puts "Restarting.."
  end
 
  # This will make sure that Capistrano doesn't try to run rake:migrate (this is not a Rails project!)
  task :cold do
    deploy.update
    deploy.start
  end
end
