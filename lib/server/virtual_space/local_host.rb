require_relative 'Connection'

class LocalHost < Connection
  #undef_method :authorize!
  #undef_method :listen
  #undef_method :disconnect
  #undef_method :reconnect!
  attr_accessor :access_trier

  def initialize(server, &on_receive_block)
    @host_id = 0
    @connected_at = Time.now
    @server = server
    @on_receive = on_receive_block
  end


  def authorized?
    true
  end

  def connected?
    true
  end

  def post(data) #overriden method for posting straight from server; here host's receiving
    @on_receive.call data
  end

  def resp(data) # for sending back
    @server.process self, data
  end

end