require "bundler/gem_tasks"
require 'rspec/core/rake_task'

# ------------------------------------ RSpec
RSpec::Core::RakeTask.new('spec')
task :test => :spec

# ------------------------------------ Server v konzoli
desc 'spuštění serveru v konzoli'
task :server do
  require_relative 'other/develop_server.rb'
end
# ------------------------------------ Client v konzoli
desc 'spuštění develop_client v konzoli'
task :klient_konzole do
  exec "gnome-terminal -x sh -c \"irb -r #{Dir.getwd}/other/develop_client.rb\""
end
