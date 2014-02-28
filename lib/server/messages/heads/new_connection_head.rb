class Messages::NewConnectionHead < Messages::Head

  def try_and_advise(data)
    if try_to_connect data
      @connection.post "#{D3ObyTCPServer::RESP_ACC_GRANTED}#{@advice_hash.to_json if @advice_hash}"
    else
      @connection.post "#{D3ObyTCPServer::RESP_ACC_DENIED}#{@advice_hash.to_json if @advice_hash}"
    end
  end

  def valid_format?
    true
  end

  def add_to_advice(**hash)
    if @advice_hash
      @advice_hash.merge! hash
    else
      @advice_hash = hash
    end
  end

  protected

  def try_to_connect(data)
    false
  end
end