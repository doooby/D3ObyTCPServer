Dir.glob "#{File.dirname(File.absolute_path(__FILE__))}/virtual_space/*.rb", &method(:require)
require_relative 'server/Server'