require 'socket'
require 'thread'
require_relative 'base'

class D3ObyTCPServer
  attr_reader :space

  def internal_order(order, conn=nil)
    #validace přikazujícího
    if !conn.nil? && true #(pozdeji skutečně validovat)
                          #PŘIPOJENÍ NEMÁ OPRÁVNĚNÍ PŘIKAZOVAT SERVERU
      return
    end
    case order
      when ''
      else
        puts " > INTERNAL ORDER: #{order}"
    end
  end

  def err_response(sc, head, err, msg=nil)
    sc.post err
    puts "\terr: #{err}"
    $stderr.puts "Error #{e.class} while servering (#{sc.id}) message >#{head}<: #{e.message}\n#{e.backtrace.join("\t\n")}." if msg.is_a? Exception
  end

  def succes_response(sc, head, scs, msg=nil)
    sc.post scs
    puts "\tscs: #{scs}"
  end

  def access_tramp(sc, data)
    if @tramp_access_trier.nil?
      false
    else
      @tramp_access_trier.access sc, data
    end
  end

  def access_guest(sc, host, data)
    raise 'Not implemented yet'
  end

  def access_host(sc,data)
    raise 'Not implemented yet'
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
        raise 'Not implemented yet'
        #succes_response(sc, orig_head, "#{RESP_ACC_GRANTED}#{sc.id}|#{sc.key}")
      else
        err_response sc, orig_head, "#{RESP_ACC_DENIED}#{msg}"
      end
      return
    elsif head=='r' #reconnection
      raise 'Not implemented yet'
    elsif head=~/^g(\d+)$/ #guest
      if $1.empty?
        err_response sc, orig_head, RESP_HEAD_INVALID
        return
      else
        try_result, msg = access_guest(sc, $1.to_i, data)
        if try_result
          raise 'Not implemented yet'
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
    unless receiver=~/^(|s|\d+(,\d+)*|a[+-]?)$/
      err_response sc, orig_head, RESP_HEAD_INVALID
      return
    end
    #####
    ####### vyřízení zprávy
    #####
    begin
      if receiver.empty? || receiver=='s'
        internal_order(body, conn)
      elsif receiver=~/^a(|\+|-)$/
        if $1.empty?
          @space.each_conn {|c| c.post body}
        elsif $1=='+'
          host = @space.get_host(sc.host)
          host.post body unless host.nil?
        elsif $1=='-'
          @space.other_conns_in_room sc {|c| c.post body}
        end
      else
        ids = $1.split(',').map{|id| id.to_i}
        ids.each do |id|
          conn = @space.get_conn id
          next if conn.nil?
          conn.post body
        end
      end
      succes_response sc, orig_head, RESP_MSG_SERVED
    rescue Exception => e
      err_response sc, orig_head, RESP_MSG_FAIL, e
    end
  end

end