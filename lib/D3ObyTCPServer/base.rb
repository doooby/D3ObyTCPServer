require 'socket'
require 'version'

module D30byTCPServer::Base
  include Helper
  include Static

  extend D3ObyTCPServer

  attr_accessor :ip, :port, :max_connections

  def initialize
    @started = false

    @listenning_socket = nil
    @listenning_thread = nil

    @max_connections = 5
    @connections = Connections.new @max_connections
    @next_connection_id = 1
    @rooms = Rooms.new
  end

  def start
    return if @started
    puts 'Starting D3ObyTCPServer'
    @socket = TCPServer.new 'localhost', 8808
    @socket.setsockopt Socket::SOL_SOCKET, Socket::SO_REUSEADDR, 1
    @started = true
    listen_for_connections

  end

  def stop
    return unless @started
    @listenning_thread.kill unless @listenning_thread.alive?
    @connections.close_all
    @listenning_socket.close
    @listenning_thread.join unless @listenning_thread.alive?
    @listenning_thread = nil
    @started = false
  end

  def listenning
    @listenning_thread!=nil && @connections.count<@max_connections
  end

  def running
    @started
  end

  private ##############################################################################################################

  def listen_for_connections
    return unless @started
    if @listenning_thread.nil?
      @listenning_thread = Thread.new do
        puts 'Server is beginning to listen for incomming connections.'
        loop do
          begin
            new_conn = @listenning_socket.accept
          rescue Errno::EAGAIN, Errno::EWOULDBLOCK, Errno::ECONNABORTED, Errno::EPROTO, Errno::EINTR
            $stderr.puts 'Incomming connection failed - skipping for next.' #IO.select([@socket])
            retry
          rescue Exception => e
            $stderr.puts "Fatal error for listenning server socket: #{e.message}."
            @listenning_thread = nil
            listen_for_connections
            Thread.current.kill
          end
          add_connection new_conn

          Thread.current.stop if Thread.current[:to_wait]
        end
      end
    else
      @listenning_thread[:to_wait] = false
      @listenning_thread.wakeup
    end
  end

  def add_connection(klient_socket)
    id = @next_connection_id
    @next_connection_id += 1
    @connections[id] = D3ObySocketConnection.new id, klient_socket, self, &method(:recieve)
    puts "Connection (#{id}) added - #{@connections.length}/#{MAX_CONNECTIONS}."
    @listenning_thread[:to_wait] = true if @connections.length==MAX_CONNECTIONS
  end

end