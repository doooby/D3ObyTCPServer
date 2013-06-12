# encoding: utf-8 
require 'socket'
require 'thread'
require './D3ObySocketConnection.rb'

class D3ObyTCPServer
  include D30byTCPServer::Base

  attr_accessor :connections, :rooms





  def disconnect(id)
    conn = @connections.delete id
    ERR_ID_NOT_CONNECTED if conn.nil?
    conn.close
    @rooms[id] if conn.host == 0
    puts "Connection (#{id}) terminated - #{@connections.length}/#{MAX_CONNECTIONS}."
    listen_for_connections if @listenning_thread[:to_wait] && @connections.length<MAX_CONNECTIONS
  end

  private ##############################################################################################################



  def access_key
    5.times do
      key = rand(65535).to_s(16)
      key = "0"*(4-key.length)+key
      already = false
      @connections.each_value do |conn|
        if conn.key==key
          already = true
          break
        end
      end
      next if already
      return key
    end
    raise "Some shit happend - generator access_key created 5 times the same value"
  end

  def internal_order(data, conn=nil)
    #validace přikazujícího
    if !conn.nil? && true #(pozdeji skutečně validovat)
                          #PŘIPOJENÍ NEMÁ OPRÁVNĚNÍ PŘIKAZOVAT SERVERU
      return
    end
    puts "INTERNAL ORDER: #{data}"
  end

  def recieve(sc, data)
    #---# délka a existence data
    unless data =~ /^\[.*\]/
      #NEVALIDNÍ ZPRÁVA
      sc.puts '[msg-invalid]'
      return
    end
                                         #---# hlavička data
    head = data.slice!(/\[.*\]/)[1..-2]
    if head=='|'
      #HLAVIČKA NENÍ VALIDNÍ
      sc.puts '[head-invalid]'
      return
    end
    response = data.slice!(0)=='?'       # přidat result a případně odesílat
    if head =~ /^n/
      #NEW CONNECTION AUTHENTIZATION REQUEST
      if head == 'nh'
        sc.key = access_key
        @rooms[sc.id] = []
        sc.host = 0
        sc.puts "[id-auth]#{sc.id},#{sc.key}"
      elsif head =~ /^ng\d+/
        sc.key = access_key
        room = @room[ head.slice(/\d+/)]
        if room.nil?
          #MÍSTNOST NEEXISTUJE
          sc.puts '[room-invalid]'
          return
        end
        room << sc.id
        sc.host = room
        sc.puts "[id-auth]#{sc.id},#{sc.key}"
      else
        #NEW CONNECTION REQUEST INVALID
        sc.puts '[head-invalid]'
      end
      return
    end
    sender,recievers = head.split '|'
                                         #---# validace odesílatele
    claimed_id = sender.slice!(/^\d*/).to_i
    if claimed_id!=0 && claimed_id!=sc.id
      #IDENTIFIKACE NENÍ VALIDNÍ
      sc.puts '[id-invalid]'
      return
    end
    type = sender.slice! 0
    unless typ =~ /^(g|h)$/
      #PŘÍCHOZÍ NEUDAL SVOJI ROLI
      sc.puts '[head-invalid]'
      return
    end
    pass_key = nil
    pass_key = sender if sender =~ /^([a-f]|\d){4}$/
    if pass_key.nil? && claimed_id==0
      #IDENTIFIKACE NENÍ VALIDNÍ
      sc.puts '[id-invalid]'
    end
    if claimed_id==0
      conn = nil
      @connections.each_value do |c|
        if c.key==pass_key
          conn=c
          break
        end
      end
      if conn.nil?
        #IDENTIFIKACE NENÍ VALIDNÍ
        sc.puts '[id-invalid]'
        return
      else
        #IDENTIFIKOVAT PODLE conn
        return
      end
    end
    conn = sc
    if conn.key!=pass_key
      #IDENTIFIKACE NENÍ VALIDNÍ
      sc.puts '[id-invalid]'
      return
    end
                                         #---# validace řetězce příjemců
    if recievers.empty? || recievers=='s'
      #INTERNÍ PŘÍKAZ
      internal_order data, conn
      return
    end
    if recievers =~ /^[\d+,]+$/
      #ODESLÁNÍ NA ZADANÉ ID
      recievers.split(',').each do |id|
        conn_to = @connections[id]
        next if conn_to.nil? || conn_to==conn
        conn_to.puts(data)
      end
      return
    elsif recievers =~ /^a[-+]?$/
      case recievers.slice 1
        when nil
          #ODESLÁNÍ VŠEM
          @connections.each_value do |c|
            next if c==conn
            c.puts data
          end
          return
        when '+'
          #ODESLÁNÍ HOSTOVI MÍSTNOSTI
          host = conn.host
          unless host.nil? || host==0
            host_conn = @connections[host]
            host_conn.puts data unless host_conn.nil?
            return
          end
        when '-'
          #ODESLÁNÍ VŠEM V MÍSTNOSTI (MIMO HOSTA)
          host = conn.host
          unless host.nil? || host==0
            @rooms[host].each do |c|
              c.puts data
            end
            return
          end
      end
    else
      #CHYBA V ZADÁNÍ PŘÍJEMCŮ
      sc.puts '[head-invalid]'
      return
    end
                                         #CHYBA VE ZPRACOVÁNÍ ZPRÁVY - NIC SE NEPROVEDLO
    sc.puts '[msg-invalid]'
  end







end