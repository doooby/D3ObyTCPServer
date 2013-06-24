class VirtualSpace
  attr_accessor :max_connections

  def initialize(server, max=10)
    @server = server
    @max_connections = max
    @actual_count = 0
    @next_connection_id = 1
    @rooms = {}
    @tramp_conns = {}
  end

  def count
    @actual_count
  end

  def each_conn(&block)
    @tramp_conns.each_value {|c| block.call c}
    @room.each_value do |room|
      room.each_guest {|c| block.call c}
      block.call room.host
    end
  end

  def each_tramp(&block)
    @tramp_conns.each_value {|c| block.call c}
  end

  def get_tramp(id)
    @tramp_conns[id]
  end

  def get_conn(id)
    @tramp_conns[id] if @tramp_conns.has_key? id
    @rooms[id].host if @rooms.has_key? id
    @rooms.each_value do |room|
      next unless room.has_guest id
      return room.get_guest id
    end
  end

  def get_room(host_id)
    @rooms[host_id]
  end

  ######################################################################################################################

  def take_next_id
    ret = @next_connection_id
    @next_connection_id += 1
    ret
  end

  def attach(socket)
    id = take_next_id
    new_conn = Connection.new id, socket, self, @server
    @actual_count += 1
    puts "Connection (#{id}) added - #{@actual_count}/#{@max_connections}."
    @server.abort_listenning if @actual_count==@max_connections
    @tramp_conns[id] = new_conn
  end

  def dettach(conn_id)
    conn_id = conn_id.id unless conn_id.is_a? Fixnum
    conn = @tramp_conns.delete conn_id
    if conn.nil?
      if @rooms.has_key? conn_id
        room = @rooms.delete conn_id
        @actual_count -= (room.guests_count + 1)
        room.close
        puts "Room (#{conn_id}) was closed and all its connections terminated for good - #{@actual_count}/#{@max_connections}"
        @server.listen_for_connections if !@server.listenning && @actual_count<@max_connections
        return
      else
        @rooms.each_value do |room|
          next unless room.has_guest conn_id
          conn = room.get_guest conn_id
        end
      end
    else
    end
    return if conn.nil?
    conn.dettach
    puts "Connection (#{conn.id}) terminated for good - #{@actual_count}/#{@max_connections}"
    @server.listen_for_connections if !@server.listenning && @actual_count<@max_connections
  end

  def deatch_all
    each_conn { |c| c.dettach }
    @actual_count = 0
    @rooms = {}
    @tramp_conns = {}
  end

  def disconnection_notice(conn)
    dettach conn
    raise 'Not implemented yet IN VirtualSpace#disconnection_notice'
  end

  def reconnect_request(proclaimed_key, conn)
    raise 'Not implemented yet IN VirtualSpace#reconnect_request'
  end

end