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

  def take_next_id
    ret = @next_connection_id
    @next_connection_id += 1
    ret
  end

  ######################################################################################################################

  def get_conn(id)
    return @tramp_conns[id] if @tramp_conns.has_key? id
    return @rooms[id].host if @rooms.has_key? id
    @rooms.each_value do |room|
      next unless room.guest? id
      return room.get_guest id
    end
  end

  def each_conn(&block)
    @tramp_conns.each_value {|c| block.call c}
    @rooms.each_value do |room|
      room.each_guest {|c| block.call c}
      block.call room.host
    end
  end

  def get_tramp(id)
    @tramp_conns[id]
  end

  def each_tramp(&block)
    @tramp_conns.each_value {|c| block.call c}
  end

  def get_room(host_id)
    @rooms[host_id]
  end

  def each_room(&block)
    @rooms.each_value {|r| block.call r}
  end

  ######################################################################################################################

  def attach(socket)
    id = take_next_id
    new_conn = Connection.new id, @server, socket
    new_conn.listen
    @actual_count += 1
    puts "Connection (#{id}) attached - #{@actual_count}/#{@max_connections}."
    @server.abort_listenning if @actual_count==@max_connections
    @tramp_conns[id] = new_conn
  end

  def attach_local_host(host)
    raise 'host not inherited from LocalHost' unless host.is_a? LocalHost
    host.id = take_next_id
    host.room = Room.new self, host
    @rooms[host.id] = host.room
    @actual_count += 1
    puts "Local host (#{host.id}) attached - #{@actual_count}/#{@max_connections}."
    @server.abort_listenning if @actual_count==@max_connections
  end

  def dettach(conn_id)
    conn_id = conn_id.id if conn_id.is_a? Connection
    conn = @tramp_conns.delete conn_id
    if conn.nil?
      if @rooms.has_key? conn_id
        room = @rooms.delete conn_id
        @actual_count -= room.guest_coun +1
        @server.host_access_trier.notice_disconection
        room.close
        puts "Room (#{conn_id}) was closed and all its connections terminated for good - #{@actual_count}/#{@max_connections}"
        @server.listen_for_connections if !@server.listenning && @actual_count<@max_connections
        return
      else
        @rooms.each_value do |room|
          next unless room.guest? conn_id
          #guest removed
          if room.host.is_a? LocalHost
            room.host.access_trier.notice_disconection
          else
            #TODO let remote host know of one guest dettached
          end
          room.dettach conn_id
        end
      end
    else
      #tramp removed
      @server.tramp_access_trier.notice_disconection
      @actual_count-=1
    end
    return if conn.nil?
    conn.close
    puts "Connection (#{conn.id}) terminated for good - #{@actual_count}/#{@max_connections}"
    @server.listen_for_connections if !@server.listenning && @actual_count<@max_connections
  end

  def dettach_all
    if @server.can_tramp_access?
      tramp_count = @tramp_conns.length
      @server.tramp_access_trier.notice_disconection tramp_count
    end
    if @server.can_host_access?
      host_count = @rooms.length
      @server.host_access_trier.notice_disconection host_count
    end
    each_conn { |c| c.close }
    @actual_count = 0
    @rooms = {}
    @tramp_conns = {}
  end

  def transfer(conn, as, to_room=nil)
    if conn.host_id==-1
      @tramp_conns.delete conn.id
    elsif conn.host_id == 0
      raise 'Not implemented yet'
    else
      raise 'Not implemented yet'
    end
    case as
      when 'h'
        @rooms[conn.id] = to_room
        conn.room = to_room
        conn.host_id = 0
      when 'g'
        to_room.attach conn
        conn.host_id = to_room.host.id
        conn.room = to_room
      else
        @tramp_conns[conn.id] = conn
        conn.host_id = -1
    end
  end

  def disconnection_notice(conn)
    conn.disconected
  end

end