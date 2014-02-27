class D3ObyTCPServer::Processor
  def initialize(connection)
    @connection = connection
  end

  def get_and_proccess_head
    @data = @connection.socket.gets "\x1D"
    if @data
      @data = @data[0..-2]
      @head = process_head
    else
      raise ConnectionClosedError(connection)
    end
  end

  def execute
    return unless @head.valid_format?
    #@data = @data.force_encoding 'utf-8'

    if @head.is_a? Messages::NewConnectionHead
      @head.try_and_advise @data unless @connection.authorized?
    else
      #authorization
      ##TODO authorize repeatedly in time
      #conn.authorize! head.key unless head.key.nil?
      #unless conn.authorized? && conn.id==head.sender
      #  if head.injunction? || head.response?
      #    conn.post "[#{"<#{head.receiver}" if head.backward?}:#{head.injunction_id}]#{RESP_ID_INVALID}"
      #  else
      #    conn.post "#{RESP_ID_INVALID}"
      #  end
      #  return
      #end
      #
      #process_sending conn, head, data
    end
  end

  private

  def process_head
    @data.slice! /^\[([^\]]*)\]/
    head_txt = $1
    return Messages::Head.new @connection unless head_txt
    case head_txt
      when ''; Messages::NewTrampConnectionHead.new @connection
      when 'r'; Messages::ReConnectionHead.new @connection
      when 'h'; Messages::NewHostConnectionHead.new @connection
      when /g(\d+)/; Messages::NewGuestConnectionHead.new @connection, $1
      else #Messages::DataHead.new head_txt
    end
  end

  def process_internal_message()
    raise 'not impleneted yet'
  end

  def handle_data
    #fail = false
    #begin
    #  ids = head.multi_receivers
    #  if ids.nil?
    #    if head.reciever=='s'
    #      #to server
    #      process_internal_injuction conn, head, data
    #    else
    #      head.post_to_recievers conn, self do |valid_reciever|
    #        post valid_reciever, conn, head, data
    #      end
    #    end
    #  else
    #    if can_over_room_reachability?
    #      ids.each do |id|
    #        c = @space.get_conn id
    #        next unless c && c.connected? && c.authorized?
    #        post c, conn, head, data
    #      end
    #    else
    #      if conn.host_id==-1
    #        ids.each do |id|
    #          c = @space.get_tramp id
    #          next unless c && c.connected? && c.authorized?
    #          post c, conn, head, data
    #        end
    #      else
    #        room = conn.room
    #        host = room.host
    #        ids.each do |id|
    #          if conn.host_id==id
    #            post host, conn, head, data if host.connected? && host.authorized?
    #          else
    #            c = room.get_guest id
    #            next unless c && c.connected? && c.authorized?
    #            post c, conn, head, data
    #          end
    #        end
    #      end
    #    end
    #  end
    #rescue Exception => e
    #  puts "FAIL | message processing : conn #{conn.id} with head >#{head.inspect}< \n\tdata >#{data}<\n\t#{e.class}: #{e.message}"+e.trace.join("\t\n")
    #  fail = true
    #ensure
    #  if head.injunction? || head.response?
    #    conn.post "[#{">#{head.receiver}" if head.backward?}:#{head.injunction_id}]#{fail ? RESP_MSG_FAIL : RESP_MSG_SERVED}"
    #  end
    #end
  end

  #def post(to, conn, head, data)
  #  return unless to.authorized?
  #  # TODO for injunction make more friendly (timeout and so on)
  #  to_post = "[#{conn.id}|#{conn.host_id}"
  #  to_post+="!#{head.injunction_id}" if head.injunction?
  #  to_post+=":#{head.injunction_id}" if head.response?
  #  to.post to_post+']'+data
  #end

end