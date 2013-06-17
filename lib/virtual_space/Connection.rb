require 'socket'

class Connection < TCPSocket
  attr_accessor :host, :key
  attr_reader :id, :thread, :connected_at

  def initialize(id, socket, space, server, &rec_callback)
    @id = id
    @connected_at = Time.now
    @socket = socket
    @space = space
    @server = server
    @callback = rec_callback.nil? ? server.method(:recieve) : rec_callback
    @authorized = false
    @host = -1
    @key = -1
    listen
  end

  def authorized?
    @authorized
  end

  def ==(other)
    false unless other.is_a? Connection
    other.id==@id
  end

  def reconnect(socket)
    raise 'Not implemented yet'
    #@socket = socket
    #listen
  end

  def close
    @socket.close unless @socket.nil? || @socked.closed?
    return if Thread.current==@thread
    unless @thread.nil?
      @thread.kill unless @thread[:to_end]
      @thread.join
    end
  end

  def send(data)
    @socket.puts data
  end

  def listen
    @thread = Thread.new do
      Thread.current[:to_end] = false
      until Thread.current[:to_end]
        begin
          data = @socket.gets
          if data.nil?
            Thread.current[:to_end] = true
            @space.acknowledge_disconnection self
          else
            data.slice! -1
          end
        rescue Exception => e
          Thread.current[:to_end] = true
          @server.errputs "Unknown error #{e.class} while recieving (#{@id}): #{e.message}." unless e.class==IOError
          @space.acknowledge_disconnection self
          @socket.close unless @socket.nil? || @socket.closed?
        end
        break if Thread.current[:to_end]
        $stdout.puts "recieved (#{@id}): >#{data}<"
        next if @callback.nil?
        begin
          @callback.call self, data
        rescue Exception => e
          @server.errputs "Error #{e.class} while invocing on_recieve call(#{@id}): #{e.message}\n#{e.backtrace.join("\t\n")}."
        end
      end
    end
  end
end