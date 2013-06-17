system 'clear'
require "#{File.dirname(File.absolute_path __FILE__)}/lib/d3oby_tcp_server.rb"
puts '############### načten zdrojový kód serveru D3ObyTCPServer #####################'

puts '>> vytvářím instanci serveru'
server = D3ObyTCPServer.new
server.start

#server.block_process_for_server
require 'shellwords'
loop do
  input = gets.strip
  args = Shellwords.shellwords input
  prikaz = args.shift
  case prikaz.downcase
    when 'exit'
      puts '>> Vypínám server ##############################################################'
      server.stop
      break
    when 'send'
      if args.count==2 && args[0] =~ /^\d*$/
        conn = server.space.get_conn args[0].to_i
        if conn.nil?
          puts ">> #{args[0].to_i} není připojeno"
        else
          conn.post args[1]
        end
      else
        puts '>> chyba příkazu: send <id> "<data/text>"'
      end
    when 'info'
      puts 'zatím neimplementováno'
      #conns = []
      #server.connections.each_value{|c| conns << c}
      #puts ">> status: IP=#{D3ObyTCPServer::IP}, port=#{D3ObyTCPServer::PORT}\n"+
      #         "\tconnections (max #{D3ObyTCPServer::MAX_CONNECTIONS}):\n"+
      #         conns.map{|c| "\tid #{c.id}: connected_at #{c.connected_at},"+
      #             " hosted by #{c.host}"}.join("\n")
    else
      puts ">> neznámý příkaz '#{prikaz}'"
  end
end
