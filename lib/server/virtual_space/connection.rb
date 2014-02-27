require 'socket'

class Connection
  attr_accessor :id, :key, :socket, :room
  attr_reader :server, :connected_at

  def initialize(id, server, socket)
    @id = id
    @room = -1
    @connected_at = Time.now
    @socket = socket
    @server = server
    @connected = true
  end

  def info
    "#{'%3s'%@id}: h=#{'%3s'%@host_id} | key=#{'%8s'%@key} | auth=#{authorized? ? 1 : 0}"
  end

  def authorize!(proclaimed_key)
    @authorized = proclaimed_key==@key
  end

  def authorized?
    @authorized
  end

  def connected?
    @connected
  end

  def disconnect
    return unless @connected
    @connected = false
    @thread[:to_end] = true
    @socket.close unless @socket.nil? || @socket.closed?
    @socket = nil
  end

  def reconnect!(conn)
    return false if @connected
    @socket = conn.socket
    conn.socket = nil
    conn.disconnect
    @connected = true
    listen
    true
  end

  def post(data)
    if @connected && @authorized
      @socket.print data
      @socket.print "\x1D"
    end
  end

  def listen
    @thread = Thread.new do
      Thread.current[:to_end] = false
      until Thread.current[:to_end]
        processor = D3ObyTCPServer::Processor.new self
        begin
          processor.get_and_proccess_head
        rescue ConnectionClosedError => e
          @server.logger.info e.message
          disconnect
        rescue IOError => e
          @server.logger.err "While reading on #@id occured #{e.class}(IOError):#{e.message}."
          disconnect
        rescue => e
          @server.logger.err "While reading on #@id occured #{e.class}:#{e.message}."
          disconnect
        end
        break if Thread.current[:to_end]
        begin
          processor.execute
        rescue => e
          @server.logger.err "While processing on#@id occured #{e.class}:#{e.message}\n#{e.backtrace.join("\t\n")}."
        end
      end
    end
  end

end

class ConnectionClosedError < StandardError
  def initialize(conn)
    super "Connection id:#{conn.id} has closed."
  end
end