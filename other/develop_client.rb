require 'socket'

AS_TRAMP = ''
AS_HOST = 'h'
AS_GUEST = 'g'

class Klient
  attr_reader :soc, :id, :key, :as, :host

  def initialize(join_as=AS_TRAMP, join_host=-1)
    @as = join_as
    @host = join_host
    @id = 0
    @waiting_resp = false
    @soc = TCPSocket.new 'localhost', 151515
    puts 'socket připojen'
  end

  def auth
    @soc.puts "[#{as}#{host if as==AS_GUEST}]"
    @soc.gets.strip.match /(\[[^\]]*\])(.+)/
    resp = $1
    msg = $2
    if resp=='[acs-granted]'
      @id, @key = msg.split('|')
      @id = @id.to_i
      listen
    else
      @id = 0
    end
    puts "AUTHENTICATE (#{@id}) resp: >#{resp}<, zpráva: >#{msg}<"
  end

  def kill
    @soc.puts "[#{@id}#{@as}]kill_conn #{@id}"
    @listener.kill
    @listener.join
  end

  def listen
    @listener = Thread.new do
      Thread.current[:to_end] = false
      until Thread.current[:to_end]
        begin
          data = @soc.gets
          if data.nil?
            Thread.current[:to_end] = true
          else
            data.slice! -1
          end
        rescue Exception => e
          Thread.current[:to_end] = true
          puts "Error #{e.class} while recieving (#{@id}): #{e.message}." unless e.class==IOError
          @soc.close unless @soc.nil? || @soc.closed?
        end
        break if Thread.current[:to_end]
        begin
          data.match /(\[[^\]]*\])(\[[^\]]*\])?(.+)/
          if $1 == '[msg-from]'
            puts "zpráva (#{$2}): >#{$3}<\n"
          else
            @waiting_resp = false
            @last_response = data
          end
        rescue Exception => e
          $stderr.puts "Error #{e.class} while proccess received >#{data}<: #{e.message}\n#{e.backtrace.join("\t\n")}."
        end
      end
    end
  end

  def post(data, to_who=nil)
    return if @waiting_resp
    @waiting_resp = true
    to_who = to_who.to_s if to_who.is_a? Fixnum
    @soc.puts "[#{@id}#{@as}#{ '|'+to_who}]#{data}"
    timeout = 10
    while timeout > 0
      unless @waiting_resp
        puts @last_response
        break
      end
      sleep 0.3
      timeout-=1
    end
    if timeout==0
      puts 'TIMEOUT RESPONSE'
      @waiting_resp = false
    end
  end
end

def conn(as=AS_TRAMP, host=-1)
  @klient = Klient.new as, host
  @klient.auth
end

def disconn
  @klient.kill
end

