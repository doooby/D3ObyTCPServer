class VirtualSpace
  attr_accessor :max_connections

  def initialize(server, max=10)
    @server = server
    @intr_ord = intr_ord
    @max_connections = max
    @actual_count = 0
    @next_connection_id = 1
    @hosts = {}
    @rooms = {}
    @unauth_conns = {}
  end

  def close_all
    each_char { |c| c.close }
    @actual_count = 0
    @hosts = {}
    @rooms = {}
    @unauth_conns = {}
  end

  def count
    @actual_count
  end

  def each_conn(&block)
    @unauth_conns.each_value {|c| block.call c}
    @hosts.each_value {|c| block.call c}
    @rooms.each_value do |room|
      room.each_value {|c| block.call c}
    end
  end

  ######################################################################################################################

  def <<(socket)
    id = @next_connection_id
    @next_connection_id += 1
    new_conn = Connection.new id, socket, self, &@server.method(:recieve)
    @server.puts "Connection (#{id}) added - #{@actual_count}/#{@max_connections}."
    @actual_count += 1
    @server.abort_listenning if @actual_count==@max_connections
    @unauth_conns[id] = new_conn
  end

  def >>(conn_id)
    conn_id = conn_id.id unless conn_id.is_a? Fixnum
    conn = @unauth_conns.delete conn_id
    if conn.nil?
      conn = @hosts.delete conn_id
      if conn.nil?
        @rooms.each_char do |h, gs|
          conn = gs.delete conn_id
          next if conn.nil?
          break
        end
      end
    end
    return unless conn.is_a? Connection
    @actual_count -= 1
    if conn.host == 0
      room = @rooms.delete conn.id
      @actual_count -= room.length
      room.each_value do |guest|
        guest.close
      end
    end
    conn.close
    @server.puts "Connection (#{conn.id}) terminated for good - #{@actual_count}/#{@max_connections}"
    listen_for_connections if !@server.listenning && @actual_count<@max_connections
  end

  def acknowledge_disconnection(conn)

  end

  def reconnect_request(key, conn)
    false
  end

end