class D3ObyTCPServer::Logger

  def log(msg, type)
  end

  def info(msg)
    log msg, :info
  end

  def err(msg)
    log msg, :err
  end
end