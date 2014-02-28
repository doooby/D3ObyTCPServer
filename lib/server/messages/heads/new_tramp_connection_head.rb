class Messages::NewTrampConnectionHead < Messages::NewConnectionHead

  protected

  def try_to_connect(data)
    if @connection.server.can_tramp_access?
      granted = @connection.server.tramp_access_trier.try_access self, data
      if granted
        @connection.authorize! -1
        add_to_advice conn_id: @connection.id
      end
      granted
    else
      add_to_advice reason: 'Tramp access disallowed'
      false
    end
  end
end