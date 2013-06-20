path = File.dirname(File.absolute_path(__FILE__))
Dir.glob "#{path}/access/*.rb", &method(:require)
Dir.glob "#{path}/virtual_space/*.rb", &method(:require)
require_relative 'server/Server'