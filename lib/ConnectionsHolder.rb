class ConnectionsHolder


  def initialize(max=10)
    @max = max
    @conns = {}
  end

  def close_all

  end

  def count
    @conns.length
  end


end