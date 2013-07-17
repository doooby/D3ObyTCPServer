class AccessTrier

  def initialize(max=10)
    @max_clients = max
    @clients = 0
  end

  def access(conn, data)
    if full?
      return false, 'Too much clients already connected.'
    else
      @clients+=1
      true
    end
  end

  def notice_disconection(count=1)
    @clients-=count
  end

  def full?
    return true if @max_clients==0
    @clients==@max_clients
  end

  def count
    @clients
  end

end