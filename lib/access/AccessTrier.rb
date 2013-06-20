class AccessTrier

  def initialize(max=5)
    @max_clients = max
    @clients = 0
  end

  def access(conn, data)
    if full?
      false
    else
      @clients+=1
      true
    end
  end

  def full?
    @clients==@max_clients
  end

end