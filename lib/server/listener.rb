require 'socket'
require 'thread'

class D3ObyTCPServer::Listener

  def initialize(server)
    @server = server
    @socket = TCPServer.new @server.ip, @server.port
    @socket.setsockopt Socket::SOL_SOCKET, Socket::SO_REUSEADDR, 1
    listen_for_connections
  rescue Errno::EADDRINUSE
    @server.logger.err "Port #{@server.port} on IP #{@server.ip} is already in use."
  end

  def listenning?
    @listenning_thread && !@listenning_thread[:to_wait]
  end

  def stop_listenning
    return unless @listenning_thread
    @listenning_thread[:to_wait] = true
  end

  def resume_listenning
    return unless @listenning_thread
    @listenning_thread[:to_wait] = false
    @listenning_thread.wakeup
  end

  def destroy
    return unless @listenning_thread
    thr = @listenning_thread
    @listenning_thread = nil
    @socket.close if @socket
    thr.kill
    thr.join
  end

  private

  def listen_for_connections
    @listenning_thread = Thread.new do
      Thread.current[:to_wait] = false
      @server.logger.info 'Server starts to listen for incomming connections.'
      loop do
        begin
          @server.space.attach_socket @socket.accept
        rescue Errno::EAGAIN, Errno::EWOULDBLOCK, Errno::ECONNABORTED, Errno::EPROTO, Errno::EINTR
          @server.logger.err 'Incomming connection failed - skipping for next.' #IO.select([@socket])
          retry
        rescue Exception => e
          @server.logger.err "Fatal error for listenning server socket: #{e.message}."
          @listenning_thread = nil
          @socket.close if @socket
          @server.on_listener_scram
          break
        end
        Thread.current.stop if Thread.current[:to_wait]
      end
    end
  end
end