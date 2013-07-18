require_relative 'data_head'

class D3ObyTCPServer

  def process(conn, data)
    head = process_head data
    if head.nil? || !head.valid?
      conn.post "[:#{head.injunction_id}]#{RESP_HEAD_INVALID}" if head.injunction?
      return
    end
    data = data.force_encoding 'utf-8'

    if head.is_a? DataHead::NewConnectionHead
      process_new_connection conn, head, data
      return
    end

    #authorization
    #TODO authorize repeatedly in time
    #TODO don't let the same connection try it endlessly
    conn.authorize! head.key unless head.key.nil?
    unless conn.authorized? && conn.id==head.sender
      if head.injunction? || head.response?
        conn.post "[#{"<#{head.receiver}" if head.backward?}:#{head.injunction_id}]#{RESP_ID_INVALID}"
      else
        conn.post "#{RESP_ID_INVALID}"
      end
      return
    end

    process_sending conn, head, data
  end

  def process_head(data)
    unless data=~/^\[([^\]]*)\]/
      return nil
    end
    head = $1
    data.slice!(0,head.length+2)
    if head.match /^(|h|g\d+|r)$/
      head = DataHead::NewConnectionHead.new $1
    else
      head = DataHead.new head
    end
    head
  end

  def process_sending(conn, head, data)
    #send
    fail = false
    begin
      ids = head.multi_receivers
      if ids.nil?
        case head.receiver
          #to server
          when 's'
            process_internal_injuction conn, head, data
          when 'h'
            post conn.room.host, conn, head, data unless conn.host_id<1 || !conn.room.host.connected?
          when 'o'
            unless conn.host_id==-1
              conn.room.each_guest do |g|
                next if g==conn || !g.connected?
                post g, conn, head, data
              end
            end
          when 'a'
            if can_send_to_all?
              if can_over_room_reachability?
                @space.each_conn do |c|
                  next if c==conn || !c.authorized? || !c.connected?
                  post c, conn, head, data
                end
              else
                @space.each_tramp do |c|
                  next if c==conn || !c.authorized? || !c.connected?
                  post c, conn, head, data
                end
              end
            end
        end
        # to selected ids
      else
        ids-=[conn.id]
        if can_over_room_reachability?
          ids.each do |id|
            c = @space.get_conn id
            next unless c && c.connected?
            post c, conn, head, data
          end
        else
          if conn.host_id==-1
            ids.each do |id|
              c = @space.get_tramp id
              next unless c && c.connected?
              post c, conn, head, data
            end
          else
            room = conn.room
            ids.each do |id|
              if conn.host_id==id
                post room.host, conn, head, data if room.host.connected?
              else
                c = room.get_guest id
                next unless c && c.connected?
                post c, conn, head, data
              end
            end
          end
        end
      end
    rescue Exception => e
      puts "FAIL | message processing : conn #{conn.id} with head >#{head.inspect}< \n\tdata >#{data}<\n\t#{e.class}: #{e.message}"+e.trace.join("\t\n")
      fail = true
    ensure
      if head.injunction? || head.response?
        conn.post "[#{"<#{head.receiver}" if head.backward?}:#{head.injunction_id}]#{fail ? RESP_MSG_FAIL : RESP_MSG_SERVED}"
      end
    end
  end

  def process_new_connection(conn, head, data)
    if head.as.empty? #tramp
      try_result, msg = false, ''
      try_result, msg = @tramp_access_trier.access conn, data if can_tramp_access?
      if try_result
        conn.authorize! -1
        conn.post "#{RESP_ACC_GRANTED}|#{conn.id}"
      else
        conn.post "#{RESP_ACC_DENIED}#{'|'+msg unless msg.nil?}"
      end
    elsif head.as=='h' #host
      try_result, msg = false, ''
      try_result, msg = @host_access_trier.access conn, data if can_host_access?
      if try_result
        conn.key = generate_access_key
        conn.authorize! conn.key
        @space.transfer conn, 'h', Room.new(self, conn)
        conn.post "#{RESP_ACC_GRANTED}|#{conn.id}|#{conn.key}"
      else
        conn.post "#{RESP_ACC_DENIED}#{'|'+msg unless msg.nil?}"
      end
    elsif head.as=='r' #reconnection
      proclaimed_id, proclaimed_host, proclaimed_key = data.split('|')
      proclaimed_conn = nil
      room = nil
      if proclaimed_id && proclaimed_host && proclaimed_key
        if proclaimed_host=='0'
          room = @space.get_room proclaimed_id.to_i
          proclaimed_conn = room.host if room
        else
          room = @space.get_room proclaimed_host.to_i
          proclaimed_conn = room.get_guest proclaimed_id.to_i
        end
      end
      if proclaimed_conn && proclaimed_conn.key==proclaimed_key
        conn.id = proclaimed_conn.id
        conn.key = proclaimed_conn.key
        conn.host_id = proclaimed_conn.host_id
        conn.room = proclaimed_conn.room
        conn.authorize! proclaimed_key
        if proclaimed_host=='0'
          room.host = conn
        else
          room.dettach proclaimed_conn
          room.attach conn
        end
        conn.post "#{RESP_ACC_GRANTED}"
      else
        conn.post "#{RESP_ACC_DENIED}"
      end
    else #guest
      room = @space.get_room head.as[1..-1].to_i
      if room.nil?
        conn.post "#{RESP_ACC_DENIED}|No such room"
      else
        if room.host.is_a? LocalHost
          try_result, msg = room.host.access_trier.access conn, data
          unless try_result
            conn.post "#{RESP_ACC_DENIED}#{'|'+msg unless msg.nil?}"
            return
          end
        else
          try_result, msg = nil, nil
          raise 'Not implemented yet'
        end
        conn.key = generate_access_key
        conn.authorize! conn.key
        @space.transfer conn, 'g', room
        conn.post "#{RESP_ACC_GRANTED}|#{conn.id}|#{conn.key}"
      end
    end
  end

  def process_internal_injuction(conn, head, data)
    internal_injuction data, conn
  end

  def post(to, conn, head, data)
    #TODO for injunction make more friendly (timeout and so on)
    to_post = "[#{conn.id}|#{conn.host_id}"
    to_post+="!#{head.injunction_id}" if head.injunction?
    to_post+=":#{head.injunction_id}" if head.response?
    to.post to_post+']'+data
  end
end