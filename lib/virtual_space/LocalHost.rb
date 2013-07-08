require_relative 'Connection'

class LocalHost < Connection

  undef_method :authorize!
  undef_method :listen
  undef_method :reconnect

  def initialize(server)
    @host = 0
    @connected_at = Time.now
    @server = server
    @authorized = true
  end


  def authorized?
    true
  end

  def dettach
  end

  def post(data)
  end

end