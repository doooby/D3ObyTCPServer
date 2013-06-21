require 'socket'

class Connection
  attr_accessor :host, :key
  attr_reader :id, :connected_at

  def initialize(id, socket, space, server, &rec_callback)
    @id = id
    @connected_at = Time.now
    @socket = socket
    @space = space
    @server = server
    @callback = rec_callback.nil? ? server.method(:receive) : rec_callback
    @authorized = false
    @host = -1
    @key = -1
    listen
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
            @space.disconnection_notice self
          else
            data.slice! -1
          end
        rescue Exception => e
          Thread.current[:to_end] = true
          unless @closing
            $stderr.puts "Unknown error #{e.class} while recieving (#{@id}): #{e.message}." unless e.class==IOError
            @space.disconnection_notice self
            @socket.close unless @socket.nil? || @socket.closed?
          end
        end
        break if Thread.current[:to_end]
        begin
          @callback.call self, data
        rescue Exception => e
          $stderr.puts "Error #{e.class} while invocing on_recieve call(#{@id}): #{e.message}\n#{e.backtrace.join("\t\n")}."
        end
      end
    end
  end
end