class VirtualSpace
  attr_accessor :max_connections

  def initialize(server, max=10)
    @server = server
    @max_connections = max.to_i
    @actual_count = 0
    @next_connection_id = 1
    @rooms = {}
    @tramp_conns = {}
  end

  def count
    @actual_count
  end

  def take_next_id
    ret = @next_connection_id
    @next_connection_id += 1
    ret
  end

  def get_conn(id)
    conn = @tramp_conns[id]
    return conn if conn
    room = @rooms[id]
    return room.host if room
    @rooms.each_value do |r|
      guest = r.get_guest id
      return guest if guest
    end
  end

  def each_conn(&block)
    @tramp_conns.each_value &block
    @rooms.each_value do |room|
      room.each_guest &block
      if block.is_a? Symbol
        room.host.send block
      else
        block.call room.host
      end
    end
  end

  def get_tramp(id)
    @tramp_conns[id]
  end

  def each_tramp(&block)
    @tramp_conns.each_value &block
  end

  def get_room(host_id)
    @rooms[host_id]
  end

  def each_room(&block)
    @rooms.each_value &block
  end

  ######################################################################################################################

  def attach_socket(socket)
    id = take_next_id
    new_conn = Connection.new id, @server, socket
    new_conn.listen
    @actual_count += 1
    @server.logger.info "Connection #{id} attached - #@actual_count/#@max_connections."
    @server.stop_listenning if @actual_count>=@max_connections
    @tramp_conns[id] = new_conn
  end

  def attach_local_host(host)
    raise "Host doesn't inherit from LocalHost." unless host.is_a? LocalHost
    host.id = take_next_id
    host.room = Room.new @server, host
    @rooms[host.id] = host.room
    @actual_count += 1
    @server.logger.info "Local host #{host.id} attached as room - #@actual_count/#@max_connections."
    @server.stop_listenning if @actual_count>=@max_connections
  end

  def detach_tramp(id)
    conn =  @tramp_conns[id]
    return unless conn
    @server.logger.info "Detaching tramp #{id}."
    @tramp_conns.delete id
  end

  def detach_room(id)
    room = @rooms[id]
    return unless room
    @server.logger.info "Detaching room #{id}."
    @rooms.delete id
  end

  def detach(connection)
    raise 'Implementing in progress'
  end

  def transfer(conn, as)
    if conn.host_id==-1
      @tramp_conns.delete conn.id
    elsif conn.host_id == 0
      raise 'Not implemented yet'
    else
      raise 'Not implemented yet'
    end
    case as
      when 'h'
        raise 'Not implemented yet'
        #@rooms[conn.id] = to_room
        #conn.room = to_room
        #conn.host_id = 0
      when /g(\d+)/
        to_room.attach conn
        conn.host_id = to_room.host.id
        conn.room = to_room
      else
        @tramp_conns[conn.id] = conn
        conn.host_id = -1
    end
  end

  def disconnection_notice(conn)
  end

end