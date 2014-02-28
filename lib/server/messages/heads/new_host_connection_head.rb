class Messages::NewHostConnectionHead < Messages::NewConnectionHead

  protected

  def try_to_connect(data)
    if @connection.server.can_host_access?
      add_to_advice reason: 'Remote host is not implemented yet'
      false
      #granted = @server.host_access_trier.try_access self, data
      #if granted
      #  @connection.key = D3ObyTCPServer.generate_access_key
      #  @connection.authorize! @connection.key
      #  add_to_advice conn_id: @connection.id, conn_key: @connection.key
      #end
      #granted
    else
      add_to_advice reason: 'Host access disallowed'
      false
    end
  end
end