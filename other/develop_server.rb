system 'clear'
require "#{Dir.getwd}/lib/d3oby_tcp_server.rb"
puts '############### načten zdrojový kód gemu d3oby_tcp_server ####################'

puts '>> vytvářím instanci serveru'
server = D3ObyTCPServer.new(
    tramp_access_trier: AccessTrier.new,
    host_access_trier: AccessTrier.new
)
server.start

#server.block_process_for_server
require 'shellwords'
loop do
  begin
  input = $stdin.gets
  break if input.nil?
  args = Shellwords.shellwords input.strip!
  prikaz = args.shift
  case prikaz.downcase
    when 'exit'
      puts '>> Vypínám server ############################################################'
      server.stop
      break
    when 'send'
      if args.count==2 && args[0] =~ /^\d*$/
        conn = server.space.get_conn args[0].to_i
        if conn.nil?
          puts ">> #{args[0].to_i} není připojeno"
        else
          conn.post args[1]
          puts ">> odesláno"
        end
      else
        puts '>> chyba příkazu: send <id> "<data/text>"'
      end
    when 'info'
      if args.count==2 && args[1] =~ /^\d*$/
        case args[0]
          when 'room'
            room = server.space.get_room args[1].to_i
            puts room.inspect
          when 'conn'
            conn = server.space.get_conn args[1].to_i
            puts conn.inspect
          else '>> chyba příkazu: info [<co> <id>]'
        end
      else
        txt = ['___tramps:']
        server.space.each_tramp {|c| txt << c.info}
        txt << '___hosts:'
        server.space.each_room do |r|
          h = r.host
          txt << "#{"(Local) " if h.is_a? LocalHost}#{h.info}"
          r.each_guest {|g| txt << "\t"+g.info}
        end
        puts ">> SERVER INFO:\n"+txt.join("\n")
      end
    when 'seek'
      if args.count==1 && args[0] =~ /^\d*$/
        conn = server.space.get_conn args[0].to_i
        puts (conn.nil? ? 'nenalezeno' : conn.info)
      end
    else
      puts ">> neznámý příkaz '#{prikaz}'"
  end
  rescue Exception => e
    puts ">> ERROR : #{e.message}\n\t"+e.backtrace.join("\n\t")
    end
end
