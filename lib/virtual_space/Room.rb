class Room

  def initialize
    @guests = {}
  end

  def has_guest(id)
    @guests.has_key? id
  end

  def get_conn(id)
    raise 'Not implemented yet IN Room#get_conn'
  end

  def each_conn(&block)
    raise 'Not implemented yet IN Room#each_conn'
  end

  def dettach(who)
    if who.is_a? Fixnum
      g = @guests[who]
      g.dettach unless g.nil?
      1
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
    else 
      0
    end
  end
end