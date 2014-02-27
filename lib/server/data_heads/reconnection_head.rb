require 'json'

class Messages::ReConnectionHead < Messages::NewConnectionHead

  protected

  def try_to_connect(data)
    data = JSON.parse data, symbolize_names: true
    proclaimed_conn = data[:conn_id].to_i
    proclaimed_key = data[:conn_key]
    as = data[:as]
    unless proclaimed_conn!=0 && proclaimed_key
      add_to_advice reason: 'Proclamation of identity missing'
      return false
    end
    conn = nil
    case as
      when nil
        conn = @connection.server.space.get_tramp proclaimed_conn
      when 'h'
        add_to_advice reason: 'Remote hosting not implemented yet'
        return false
      when /^g(\d+)$/
        room = @connection.server.space.get_room $1
        if room
          conn = room.get_guest proclaimed_conn
        else
          add_to_advice reason: 'No such room'
          return false
        end
    end
    unless conn && conn.key==proclaimed_key
      add_to_advice reason: 'Bad proclamation of identity'
      return false
    end
    unless conn.reconnect! @connection
      add_to_advice reason: 'Proclaimed connection is still active'
      false
    end
    conn.key = D3ObyTCPServer.generate_access_key
    conn.authorize! conn.key
    add_to_advice conn_id: conn.id, conn_key: conn.key
    conn.server.space.detach_tramp @connection.id
    @connection = conn
    true
  rescue JSON::ParserError
    add_to_advice reason: 'Data JSON parsing error'
    false
  end
end