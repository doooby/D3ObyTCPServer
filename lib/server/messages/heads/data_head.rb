
class Messages::DataHead < Messages::Head
  attr_reader :original, :sender, :as, :key, :receiver, :injunction_id

  def initialize(data)
    @valid = true
    #@original = data.dup

    injunction = data.slice! /[!:]\d*$/
    unless injunction.nil?
      @injunction = injunction.slice! 0
      @injunction_id = injunction.to_i
    end
    receiver = data.slice! /[><].+$/
    @sending_side = receiver.slice! 0 unless receiver.nil?
    @receiver = (receiver.nil? ? 's' : receiver)
    @multi_ids = !(@receiver=~/^(\d+,)*\d+$/).nil?
    @valid = false unless @receiver=~/^[shoa]$/ unless @multi_ids

    if data=~/^(\d+)([gh][a-f\d]{8}?)?$/
      @sender = $1.to_i
      if $2.nil?
        @as = ''
      else
        @as = $2[0]
        @key = $2[1..0] if $2.length>1
      end
    else
      @valid = false
    end
  end

  def valid_format?
    @valid
  end

  def injunction?
    @injunction == '!'
  end

  def response?
    @injunction == ':'
  end

  def foreward?
    @sending_side == '>'
  end

  def backward?
    @sending_side == '<'
  end

  def multi_receivers
    return nil unless @multi_ids
    @receiver.split(',').map{|id| id.to_i}.uniq - [@sender]
  end

  def each_reciever(conn, server, &block)
    if @multi_ids

    else
      if head.reciever=='s'
        #to server
        server.process_internal_injuction conn, head, data
      else
        head.post_to_recievers conn, self do |valid_reciever|
          post valid_reciever, conn, head, data
        end
      end
    end
  end

  def post_to_recievers(conn, server, &block)
    case receiver
      when 'h'
        host = conn.room.host
        if conn.host_id>0 && host.connected? && host.authorized?
          post host, conn, head, data
        end
      when 'o'
        unless conn.host_id==-1
          conn.room.each_guest do |g|
            next unless g!=conn && g.connected? && g.authorized?
            post g, conn, head, data
          end
        end
      when 'a'
        if can_send_to_all?
          if can_over_room_reachability?
            @space.each_conn do |c|
              next unless c!=conn && c.connected? && c.authorized?
              post c, conn, head, data
            end
          else
            @space.each_tramp do |c|
              next unless c!=conn && c.connected? && c.authorized?
              post c, conn, head, data
            end
          end
        end
    end

  end

end