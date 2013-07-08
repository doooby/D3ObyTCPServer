require 'socket'
require 'timeout'
require_relative '../lib/server/static'

class Client
  attr_reader :id, :key, :host, :waiting_resp, :socket, :listener

  def initialize(**args)
    @id = 0
    @key = -1
    @host = -1
    @waiting_resp = false

    #server ip
    ip = 'localhost'
    ip = args[:ip] if args.has_key? :ip
    #server port
    port = 151515
    port = args[:port] if args.has_key? :port
    #receiver
    @receive = nil
    @receive = args[:receive] if args.has_key? :receive

    @socket = TCPSocket.new ip, port
    puts 'socket připojen'
  end

  def connected?
    @id!=0
  end

  def logg_in(as='')
    @socket.puts "[#{as}]"
    @socket.gets.strip.match /(\[[^\]]*\])(.+)/

    if $1==D3ObyTCPServer::Static::RESP_ACC_GRANTED
      @id, @key = $2.split('|')
      @id = @id.to_i
      @as = as
      if @as=='h'
        @host = 0
      elsif @as=~/g(\d*)/
        @host = $1.to_i
        @as = 'g'
      end
      listen
    else
      @id = 0
    end
    puts "AUTHENTICATE (#{@id}) key: >#{@key}<"
  end

  def logg_off
    @listener[:to_end] = true
    @socket.puts "[#{@id}#{@as}]kill_conn #{@id}"
    begin
      timeout(3) { @listener.join }
    rescue
      @listener.kill
      retry
    end
  end

  def listen
    @listener = Thread.new do
      Thread.current[:to_end] = false
      until Thread.current[:to_end]
        begin
          data = @socket.gets
          puts "doručeno >#{data}<"
          if data.nil?
            Thread.current[:to_end] = true
          else
            data.slice! -1
          end
        rescue Exception => e
          Thread.current[:to_end] = true
          puts "Error #{e.class} while recieving (#{@id}): #{e.message}." unless e.class==IOError
          @socket.close unless @socket.nil? || @socket.closed?
          @id = 0
        end
        break if Thread.current[:to_end]
        begin
          head = data.slice!(/\[[^\]]*\]/)
          if head.nil?
            puts "unrecognized message: >#{data}<"
          else
            head.slice!(1..-2)
            if head=~/^(\d*)(\|\d+)$/
              @receive.call data, $1, ($2.nil? ? nil : $2[1..-1]) unless @receive.nil?
            else
              #internal server messages:
              @last_response = head
              @waiting_resp = false
              #case head
              #  when D3ObyTCPServer::Static::RESP_MSG_SERVED
              #end
            end
          end
        rescue Exception => e
          $stderr.puts "Error #{e.class} while proccess received >#{data}<: #{e.message}\n#{e.backtrace.join("\t\n")}."
          @id=0
        end
      end
    end
  end

  def post(data, to_who=nil)
    return if @waiting_resp
    @waiting_resp = true
    to_who = to_who.to_s if to_who.is_a? Fixnum
    @socket.puts "[#{@id}#{@as}#{'|'+to_who}]#{data}"
    begin
      timeout (3) do
        unless @waiting_resp
          puts @last_response
          break
        end
        sleep 0.3
      end
    rescue
      puts 'response timeout'
      @waiting_resp = false
    end
  end

end