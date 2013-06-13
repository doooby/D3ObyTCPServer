require 'socket'
require 'version'

class D30byTCPServer

  attr_reader :ip, :port

  def initialize
    @sout = $stdout
    @serout = $stderr

    @started = false

    @listenning_socket = nil
    @listenning_thread = nil

    @space = VirtualSpace.new 5
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
    @space.close_all
    @listenning_socket.close
    @listenning_thread.join unless @listenning_thread.alive?
    @listenning_thread = nil
    @started = false
  end

  def running
    @started
  end

  def puts(text)
    @sout.puts text
  end

  def errputs(text)
    @serout.puts text
  end

  ######################################################################################################################

  def listen_for_connections
    return unless @started
    if @listenning_thread.nil?
      @listenning_thread = Thread.new do
        Thread.current[:to_wait] = false
        puts 'Server is beginning to listen for incomming connections.'
        loop do
          begin
            new_conn = @listenning_socket.accept
          rescue Errno::EAGAIN, Errno::EWOULDBLOCK, Errno::ECONNABORTED, Errno::EPROTO, Errno::EINTR
            errputs 'Incomming connection failed - skipping for next.' #IO.select([@socket])
            retry
          rescue Exception => e
            errputs "Fatal error for listenning server socket: #{e.message}."
            @listenning_thread = nil
            listen_for_connections
            Thread.current.kill
          end
          @space << new_conn

          Thread.current.stop if Thread.current[:to_wait]
        end
      end
    else
      @listenning_thread[:to_wait] = false
      @listenning_thread.wakeup
    end
  end

  def listenning
    !@listenning_thread.nil? && @listenning_thread[:to_wait]
  end

  def abort_listenning
    @listenning_thread[:to_wait]
  end

end