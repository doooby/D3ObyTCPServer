class Room
  attr_reader :host

  def initialize(server, host)
    @server = server
    @host = host
    @guests = {}
  end

  def get_guest(id)
    @guests[id]
  end

  def each_guest(&block)
    @guests.each_value &block
  end

  def guests_count
    @guests.length
  end

  def attach(guest)
    @guests[guest.id] = guest
  end

  def detach_guest(id)
    conn =  @guests[id]
    return unless conn
    @guests.delete id
  end
end