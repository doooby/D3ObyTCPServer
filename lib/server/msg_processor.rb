require_relative 'data_head'

class D3ObyTCPServer


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

  def process(conn, data)
    head = process_head data
    if head.nil? || !head.valid?
      conn.post "[:#{head.injunction_id}]#{RESP_HEAD_INVALID}" if head.injunction?
      return
    end

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
            process_sending conn.room.host, conn, head, data unless conn.host<0
          when 'o'
            unless conn.host==-1
              conn.room.each_guest do |g|
                next if g==conn
                process_sending g, conn, head, data
              end
            end
          when 'a'
            if can_send_to_all?
              if can_over_room_reachability?
                @space.each_conn do |c|
                  next if c==conn
                  process_sending c, conn, head, data
                end
              else
                @space.each_tramp do |c|
                  next if c==conn
                  process_sending c, conn, head, data
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
            next unless c
            process_sending c, conn, head, data
          end
        else
          if conn.host==-1
            ids.each do |id|
              c = @space.get_tramp id
              next unless c
              process_sending c, conn, head, data
            end
          else
            room = conn.room
            ids.each do |id|
              if conn.host==id
                process_sending room.host, conn, head, data
              else
                c = room.get_guest id
                next unless c
                process_sending c, conn, head, data
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
        conn.post "#{RESP_ACC_DENIED}|#{msg}"
      end
    elsif head.as=='h' #host
                       #TODO connect as host remotely
      raise 'not implemented yet'
                      #try_result, msg = false, ''
                      #try_result, msg = @host_access_trier.access conn, data if can_host_access?
                      #if try_result
                      #  conn.key = generate_access_key
                      #  conn.authorize! conn.key
                      #  conn.room = Room.new conn, @guest_access_trier
                      #  @space.transfer conn, 'h'
                      #  succes_response conn, orig_head, "#{RESP_ACC_GRANTED}#{conn.id}|#{conn.key}"
                      #else
                      #  err_response conn, orig_head, "#{RESP_ACC_DENIED}#{msg}"
                      #end
    elsif head.as=='r' #reconnection
                       #TODO reconnection process
      raise 'Not implemented yet'
    else #guest
      room = @space.get_room head.as[1..-1].to_i
      if room.nil?
        conn.post "#{RESP_ACC_DENIED}|No such room"
      else
        try_result, msg = room.access_trier.access conn, data
        if try_result
          conn.key = generate_access_key
          conn.authorize! conn.key
          @space.transfer conn, 'g', room
          conn.post "#{RESP_ACC_GRANTED}|#{conn.id}|#{conn.key}"
        else
          conn.post "#{RESP_ACC_DENIED}|#{msg}"
        end
      end
    end
  end

  def process_internal_injuction(conn, head, data)
    internal_injuction data, conn
  end

  def process_sending(to, conn, head, data)
    #TODO for injunction make more friendly (timeout and so on)
    to_post = "[#{conn.id}|#{conn.host}"
    to_post+="!#{head.injunction_id}" if head.injunction?
    to_post+=":#{head.injunction_id}" if head.response?
    to.post to_post+']'+data
  end
end