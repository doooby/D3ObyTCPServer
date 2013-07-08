require 'socket'
require_relative 'Client'

$k = Client.new receive: methods(:vypis)

def log(as)
  $k.logg_in as
end

def exit
  $k.kill
  exit
end