path = File.dirname(File.absolute_path(__FILE__))

require "#{path}/server/version"
require "#{path}/server/constants"
require "#{path}/server/core/settings"
require "#{path}/server/core/callbacks"
require "#{path}/server/core/server"
require "#{path}/server/logger"
require "#{path}/server/listener"
require "#{path}/server/processor"

require "#{path}/server/virtual_space/virtual_space"
require "#{path}/server/virtual_space/connection"
require "#{path}/server/virtual_space/room"
require "#{path}/server/virtual_space/local_host"
require "#{path}/server/virtual_space/access/access_trier"

require "#{path}/server/messages/messages"
require "#{path}/server/messages/heads/head"
require "#{path}/server/messages/heads/new_connection_head"
require "#{path}/server/messages/heads/new_tramp_connection_head"
require "#{path}/server/messages/heads/new_host_connection_head"
require "#{path}/server/messages/heads/new_guest_connection_head"
require "#{path}/server/messages/heads/data_head"