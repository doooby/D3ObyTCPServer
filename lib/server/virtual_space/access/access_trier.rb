class AccessTrier

  def initialize(max=10)
    @max_clients = max
    @clients = 0
  end

  def try_access(head, data)
    if full?
      head.add_to_advice reason: 'Too many clients already connected.'
      false
    else
      @clients += 1
      true
    end
  end

  def register_disconnection(count=1)
    @clients -= count
  end

  def full?
    return true if @max_clients==0
    @clients==@max_clients
  end

  def count
    @clients
  end

end