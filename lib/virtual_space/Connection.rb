require 'socket'

class Connection
  attr_accessor :id, :host_id, :key, :room
  attr_reader :connected_at

  def initialize(id, server, socket)
    @id = id
    @host_id = -1
    @key = -1
    @connected_at = Time.now
    @socket = socket
    @server = server
    @authorized = false
    @connected = true
  end

  def info
    "#{'%3s'%@id}: h=#{'%3s'%@host_id} | key=#{'%8s'%@key} | auth=#{authorized? ? 1 : 0} | at=#{@connected_at.strftime '%H:%M:%S'}"
  end

  def authorize!(proclaimed_key)
    @authorized = proclaimed_key==@key
  end

  def authorized?
    @authorized
  end

  def ==(other)
    false unless other.is_a? Connection
    other.id==@id
  end

  def disconected
    @connected = false
  end

  def connected?
    @connected
  end

  def reconnect(conn)
    raise 'Not implemented yet IN Connection#reconnect'
    #@socket = socket
    #listen
  end

  def close
    @closing = true
    @socket.close unless @socket.nil? || @socket.closed?
    return if Thread.current==@thread
    unless @thread.nil?
      @thread.kill unless @thread[:to_end]
      @thread.join
    end
  end

  def post(data)
    @socket.puts data unless @closing || !@authorized
  end

  def listen
    @thread = Thread.new do
      Thread.current[:to_end] = false
      until Thread.current[:to_end]
        begin
          data = @socket.gets
          if data.nil?
            Thread.current[:to_end] = true
            @server.space.disconnection_notice self
          else
            data.slice! -1
          end
        rescue Exception => e
          Thread.current[:to_end] = true
          unless @closing
            $stderr.puts "Unknown error #{e.class} while recieving (#{@id}): #{e.message}." unless e.class==IOError
            @server.space.disconnection_notice self
            unless @socket.nil? || @socket.closed?
              @socket.close
              @socket = nil
              @authorized = false
            end
          end
        end
        break if Thread.current[:to_end]
        begin
          @server.process self, data
        rescue Exception => e
          $stderr.puts "Error #{e.class} while invocing on_recieve call(#{@id}): #{e.message}\n#{e.backtrace.join("\t\n")}."
        end
      end
    end
  end
end