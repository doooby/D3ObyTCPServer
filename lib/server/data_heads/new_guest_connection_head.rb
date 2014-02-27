class Messages::NewGuestConnectionHead < Messages::NewConnectionHead
  def initialize(connection, room_id)
    super(connection)
    @room_id = room_id
  end

  protected

  def try_to_connect(data)
    room = @connection.server.space.get_room @room_id
    unless room
      add_to_advice reason: 'No such room'
      return false
    end
    if room.host.is_a? LocalHost
      granted = room.host.access_trier.try_access self, data
      if granted
        @connection.key = D3ObyTCPServer.generate_access_key
        @connection.authorize! @connection.key
        @connection.server.space.transfer @connection, "g#{room}"
        add_to_advice conn_id: @connection.id, conn_key: @connection.key
      end
      granted
    else
      raise 'Not implemented yet - RemoteHost-ing'
    end
  end
end