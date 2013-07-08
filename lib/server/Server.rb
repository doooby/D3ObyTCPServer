require 'socket'
require 'thread'
require_relative 'base'

class D3ObyTCPServer
  attr_reader :space

  def internal_order(order, conn=nil)
    puts "\tINTERNAL ORDER: #{order}"

    #---------------------------------
    if order.match /^kill_conn (\d*)$/
      who = $1.to_i
      if conn.nil?
        raise 'Not implemented yet IN Server#internal_order - kill_conn - without conn'
      else
        if who==conn.id
          @space.dettach conn.id
          true
        elsif conn.host==0
          if conn.room.guest? who.id
            @space.dettach who.id
            true
          else
            return false, "cannot kill guest when you are not hosting"
          end
        else
          return false, "cannot kill others (only if you are guests)"
        end
      end
    #---------------------------------
    elsif true
      return false, 'unknown command'
    end

  end

  def err_response(sc, head, err)
    sc.post err
    puts "\terr: #{err}"
  end

  def succes_response(sc, head, scs)
    sc.post scs
    puts "\tsuccess: #{scs}"
  end

  def receive(sc, data)
    #####
    ####### délka a konzistence data
    #####
    puts ">> RECEIVE sc: #{sc.id}, data: >#{data}<"
    unless data=~/^\[([^\]]*)\]/
      err_response sc, data, RESP_MSG_INVALID
      return
    end
    orig_head = $1.dup
    head = $1
    data.slice!(0,head.length+2)
    puts "\thead: >#{orig_head}<"
    if head=='|'
      err_response sc, orig_head, RESP_HEAD_INVALID
      return
    end
    #####
    ####### žádost o přítup?
    #####
    #TODO přeřazení, tj. již jednou udělen přístup, snaha o změnu pozice
    if head.empty? #tramp
      try_result, msg = false, ''
      try_result, msg = @tramp_access_trier.access sc, data if can_tramp_access?
      if try_result
        sc.authorize! -1
        succes_response sc, orig_head, "#{RESP_ACC_GRANTED}#{sc.id}"
      else
        err_response sc, orig_head, "#{RESP_ACC_DENIED}#{msg}"
      end
      return
    elsif head=='h' #host
      try_result, msg = false, ''
      try_result, msg = @host_access_trier.access sc, data if can_host_access?
      if try_result
        sc.key = generate_access_key
        sc.authorize! sc.key
        sc.room = Room.new sc, @guest_access_trier
        @space.regrade sc, 'h'
        succes_response sc, orig_head, "#{RESP_ACC_GRANTED}#{sc.id}|#{sc.key}"
      else
        err_response sc, orig_head, "#{RESP_ACC_DENIED}#{msg}"
      end
      return
    elsif head=='r' #reconnection
      #TODO reconnection process
      raise 'Not implemented yet IN Server#receive #2'
    elsif head=~/^g(\d+)$/ #guest
      if $1.empty?
        err_response sc, orig_head, RESP_HEAD_INVALID
        return
      else
        room = @space.get_room $1.to_i
        msg = nil
        unless room.nil?
          try_result, msg = room.access_trier.access sc, data
          if try_result
            sc.key = generate_access_key
            sc.authorize! sc.key
            @space.regrade sc, 'g', room
            #TODO access as guest
            succes_response sc, orig_head, "#{RESP_ACC_GRANTED}#{sc.id}|#{sc.key}"
            return
          end
        end
        err_response sc, orig_head, "#{RESP_ACC_DENIED}#{msg}"
        return
      end
    end
    #####
    ####### kdo a komu
    #####
    sender,receiver = head.split '|'
    puts "\tsender: >#{sender}<, receiver: >#{receiver}<"
    #sender
    sender_valid = true
    sender_valid = false unless sender=~/^(\d+)([gh]?)([a-f\d]{8})?$/
    puts "\tclaimed_id: >#{$1}<, role: >#{$2}<, auth: >#{$3}<"
    unless sender_valid && $1.to_i==sc.id
      err_response sc, orig_head, RESP_ID_INVALID
      return
    end
    if $2.empty?
      sender_valid = false unless sc.host==-1
    elsif $2=='h'
      sender_valid = false unless sc.host==0
    elsif $2=='g'
      sender_valid = false unless sc.host>0
    end
    unless sender_valid
      err_response sc, orig_head, RESP_ID_INVALID
      return
    end
    if sc.authorized?
      # TODO časové omezení autorizace
    else
      unless sc.authorize! $3
        err_response sc, orig_head, RESP_ID_AUTHORIZE
        return
      end
    end
    #receiver
    receiver = 's' if receiver.nil? || receiver.empty?
    unless receiver=~/^(s|h|o|a|\d+(,\d+)*)$/
      err_response sc, orig_head, RESP_HEAD_INVALID
      return
    end
    #####
    ####### vyřízení zprávy
    #####
    begin
      case receiver
        when 's' #to server
          order_resp, msg = internal_order(data, sc)
          unless order_resp
            err_response sc, orig_head, "#{RESP_ORDER_FORBIDDEN}#{msg}"
            return
          end
        when 'h' #to host only
          @space.get_room(sc.host).host.post "[#{sc.id}]#{data}"
        when 'o' #to every other in room
          if sc.host==-1
            err_response sc, orig_head, "#{RESP_MSG_INVALID}No room joined"
            return
          else
            resp = "[#{sc.id}]#{data}"
            sc.room.each_guest {|g| g.post resp unless g==sc}
            sc.room.host.post resp unless sc.host==0
          end
        when 'a' #to all
          resp = "[#{sc.id}|#{sc.host}]#{data}"
          if can_over_room_reachability?
            @space.each_conn {|c| c.post resp unless c==sc}
          else
            @space.each_tramp {|c| c.post resp unless c==sc}
          end
        else #to specified connections
          ids = receiver.split(',').map{|id| id.to_i}
          resp = "[#{sc.id}|#{sc.host}]#{data}"
          ids.each do |id|
            conn = @space.get_conn id
            next if conn.nil?
            same_room = ((conn.host==sc.host && conn.host>0) || conn.host==sc.id || conn.id==sc.host)
            if same_room || can_over_room_reachability?
              conn.post resp
            end
          end
      end
      succes_response sc, orig_head, RESP_MSG_SERVED
    rescue Exception => e
      err_response sc, orig_head, RESP_MSG_FAIL
      puts >> "ERR IN RECEIVE : #{e.message}"+e.trace.join("\t\n")
    end
  end

end