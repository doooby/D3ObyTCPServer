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
          if @space.get_room(conn.id).has_guest(who.id)
            @space.dettach who.id
            true
          else
            false
          end
        else
          false
        end
      end
    #---------------------------------
    elsif true
      false
    end

  end

  def err_response(sc, head, err, msg=nil)
    sc.post err
    puts "\terr: #{err}"
    $stderr.puts "Error #{msg.class} while servering (#{sc.id}) message >#{head}<: #{msg.message}\n#{msg.backtrace.join("\t\n")}." if msg.is_a? Exception
  end

  def succes_response(sc, head, scs, msg=nil)
    sc.post scs
    puts "\tsuccess: #{scs}"
  end

  def access_tramp(sc, data)
    if @tramp_access_trier.nil?
      false
    else
      @tramp_access_trier.access sc, data
    end
  end

  def access_guest(sc, host, data)
    raise 'Not implemented yet IN Server#access_guest'
  end

  def access_host(sc,data)
    raise 'Not implemented yet IN Server#access_host'
  end

  def receive(sc, data)
    #####
    ####### délka a konzistence data
    #####
    puts "IN: receive, sc: #{sc.id}, data: >#{data}<"
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
    if head.empty? #tramp
      try_result, msg = access_tramp(sc, data)
      if try_result
        sc.authorize! -1
        succes_response sc, orig_head, "#{RESP_ACC_GRANTED}#{sc.id}"
      else
        err_response sc, orig_head, "#{RESP_ACC_DENIED}#{msg}"
      end
      return
    elsif head=='h' #host
      try_result, msg = access_host(sc, data)
      if try_result
        raise 'Not implemented yet IN Server#receive #1'
        #succes_response(sc, orig_head, "#{RESP_ACC_GRANTED}#{sc.id}|#{sc.key}")
      else
        err_response sc, orig_head, "#{RESP_ACC_DENIED}#{msg}"
      end
      return
    elsif head=='r' #reconnection
      raise 'Not implemented yet IN Server#receive #2'
    elsif head=~/^g(\d+)$/ #guest
      if $1.empty?
        err_response sc, orig_head, RESP_HEAD_INVALID
        return
      else
        try_result, msg = access_guest(sc, $1.to_i, data)
        if try_result
          raise 'Not implemented yet IN Server#receive #3'
          #succes_response(sc, orig_head, "#{RESP_ACC_GRANTED}#{sc.id}|#{sc.key}")
        else
          err_response sc, orig_head, "#{RESP_ACC_DENIED}#{msg}"
        end
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
    sender_valid = false unless sender=~/^(\d+)(|h|g)([a-f\d]{4})?$/
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
    unless receiver=~/^(s|\d+(,\d+)*|a[+-]?)$/
      err_response sc, orig_head, RESP_HEAD_INVALID
      return
    end
    #####
    ####### vyřízení zprávy
    #####
    begin
      resp_data = "#{RESP_MSG_FROM}[#{sc.id}|#{sc.host}]#{data}"
      if receiver=='s'
        if internal_order(data, sc)
          return
        else
          err_response sc, orig_head, RESP_ORDER_FORBIDDEN
          return
        end
      elsif receiver=~/^a(|\+|-)$/
        if $1.empty?
          @space.each_conn {|c| c.post resp_data}
        elsif $1=='+'
          host = @space.get_host(sc.host)
          host.post resp_data unless host.nil?
        elsif $1=='-'
          @space.other_conns_in_room sc {|c| c.post resp_data}
        end
      else
        ids = receiver.split(',').map{|id| id.to_i}
        ids.each do |id|
          conn = @space.get_conn id
          next if conn.nil?
          conn.post resp_data
        end
      end
      succes_response sc, orig_head, RESP_MSG_SERVED
    rescue Exception => e
      err_response sc, orig_head, RESP_MSG_FAIL, e
    end
  end

end