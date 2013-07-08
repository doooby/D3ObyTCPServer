class Room
  attr_reader :host, :access_trier

  def initialize(host, access_trier)
    @host = host
    @guests = {}
    @access_trier = access_trier
  end

  def guest?(id)
    @guests.has_key? id
  end

  def get_guest(id)
    @guests[id]
  end

  def each_guest(&block)
    @guests.each_value {|g| block.call g}
  end

  def guests_count
    @guests.length
  end

  def attach(guest)
    @guests[guest.id] = guest
  end

  def dettach(who)
    if who.is_a? Fixnum
      g = @guests[who]
      unless g.nil?
        g.dettach
        1
      end
    elsif who.is_a? Array
      detached = 0
      who.each do |id|
        g = @guests[id]
        unless g.nil?
          detached+=1
          g.dettach
        end
      end
      detached
    elsif who.is_a? TrueClass
      detached = @guests.length
      @guests.each_value {|g| g.dettach}
      detached
    end
    0
  end

  def close
    dettach true
    @host.dettach
  end
end