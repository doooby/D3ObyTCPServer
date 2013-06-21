class VirtualSpace
  attr_accessor :max_connections

  def initialize(server, max=10)
    @server = server
    #@intr_ord = intr_ord
    @max_connections = max
    @actual_count = 0
    @next_connection_id = 1
    @hosts = {}
    @rooms = {}
    @tramp_conns = {}
  end

  def deatch_all
    each_conn { |c| c.dettach }
    @actual_count = 0
    @hosts = {}
    @rooms = {}
    @tramp_conns = {}
  end

  def count
    @actual_count
  end

  def each_conn(&block)
    @tramp_conns.each_value {|c| block.call c}
    @hosts.each_value {|c| block.call c}
    @rooms.each_value do |room|
      room.each_conn {|c| block.call c}
    end
  end

  def other_conns_in_room(conn, &block)
    room = @rooms[conn.host]
    return if room.nil?
    room.each_conn {|c| block.call c unless c==conn}
  end

  def get_conn(id)
    conn = @tramp_conns[id]
    return conn unless conn.nil?
    conn = @hosts[id]
    return conn unless conn.nil?
    @rooms.each_value do |room|
      conn = room.get_conn id
      return conn unless conn.nil?
    end
  end

  def get_host(id)
    @hosts[id]
  end

  def get_room(host_id)
    @rooms[host_id]
  end

  ######################################################################################################################

  def attach(socket)
    id = @next_connection_id
    @next_connection_id += 1
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
      @actual_count -= room.dettach(true)
    end
    conn.dettach
    puts "Connection (#{conn.id}) terminated for good - #{@actual_count}/#{@max_connections}"
    @server.listen_for_connections if !@server.listenning && @actual_count<@max_connections
  end

  def disconnection_notice(conn)
    dettach conn
    raise 'Not implemented yet IN VirtualSpace#disconnection_notice'
  end

  def reconnect_request(proclaimed_key, conn)
    raise 'Not implemented yet IN VirtualSpace#reconnect_request'
  end

end