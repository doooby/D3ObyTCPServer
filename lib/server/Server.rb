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
        puts "INTERNAL ORDER: #{order}"
    end
  end

  def err_response(sc, data, err, msg=nil)
    sc.puts err
  end

  def receive(sc, data)
    #####
    ####### délka a konzistence data
    #####
    unless data=~/^\[.*\]/
      err_response sc, data, RESP_MSG_INVALID
      return
    end
    body = data
    head = body.slice!(/^\[[^\]]\]/)[1..-2]
    if head=='|'
      err_response sc, data, RESP_HEAD_INVALID
      return
    end
    #####
    ####### žádost o přítup?
    #####
    if head.empty?
      #volný přístup
      raise 'Not implemented yet'
    elsif head=='h'
      #přístup jako host
      raise 'Not implemented yet'
    elsif head=='r'
      #žádost o obnovení spojení
      raise 'Not implemented yet'
    elsif head=~/^g(\d+)$/
      #přístup jako guest do místnosti $1
      raise 'Not implemented yet'
    end
    #####
    ####### kdo a komu
    #####
    sender,receiver = head.split '|'
    #sender
    sender_valid = true
    sender_valid = false unless sender=~/^(\d+)(|(h|g)[a-f\d]{4})$/
    unless $1.to_i==sc.id &&sender_valid
      err_response sc, data, RESP_ID_INVALID
      return
    end
    $2.match /^(|h|g)([a-f\d]{4})$/
    sender_valid = true
    if $1.empty?
      sender_valid = false unless sc.host==-1
    elsif $1=='h'
      sender_valid = false unless sc.host==0
    elsif $1=='g'
      sender_valid = false unless sc.host>0
    end
    unless sender_valid
      err_response sc, data, RESP_ID_INVALID
      return
    end
    if sc.authorized?
      # TODO časové omezení autorizace
    else
      unless sc.authorize! $2
        err_response sc, data, RESP_ID_AUTHORIZE
        return
      end
    end
    #receiver
    unless receiver=~/^(|s|\d+(,\d+)*|a[+-]?)$/
      err_response sc, data, RESP_HEAD_INVALID
      return
    end
    #####
    ####### vyřízení zprávy
    #####
    if receiver.empty? || receiver=='s'
      internal_order body, conn
    elsif receiver=~/^a(|\+|-)$/
      if $1.empty?
        @space.each_conn {|c| c.post body}
      elsif $1=='+'
        host = @space.get_host(sc.host)
        host.post body unless host.nil?
      elsif $1=='-'
        @space.every_other_conn_in_room sc {|c| c.post body}
      end
    else
      ids = $1.split(',').map{|id| id.to_i}
      ids.each do |id|
        conn = @space.get_conn id
        next if conn.nil?
        conn.post body
      end
    end
  end

end