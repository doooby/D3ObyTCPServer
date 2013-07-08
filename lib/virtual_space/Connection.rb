require 'socket'

class Connection
  attr_accessor :id, :host, :key, :room
  attr_reader :connected_at

  def initialize(id, server, socket)
    @id = id
    @host = -1
    @key = -1
    @connected_at = Time.now
    @socket = socket
    @server = server
    @authorized = false
    listen
  end

  def info
    "#{'%3s'%@id}: h=#{'%3s'%@host} | key=#{'%8s'%@key} | auth=#{authorized? ? 1 : 0} | at=#{@connected_at.strftime '%H:%M:%S'}"
  end

  def authorize!(proclaimed_key)
    if proclaimed_key==@key
      @authorized = true
      true
    else
      @authorized = false
      false
    end
  end

  def authorized?
    @authorized
  end

  def ==(other)
    false unless other.is_a? Connection
    other.id==@id
  end

  def reconnect(socket)
    raise 'Not implemented yet IN Connection#reconnect'
    #@socket = socket
    #listen
  end

  def dettach
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
            @socket.close unless @socket.nil? || @socket.closed?
          end
        end
        break if Thread.current[:to_end]
        begin
          @server.receive self, data
        rescue Exception => e
          $stderr.puts "Error #{e.class} while invocing on_recieve call(#{@id}): #{e.message}\n#{e.backtrace.join("\t\n")}."
        end
      end
    end
  end
end