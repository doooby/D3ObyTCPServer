require_relative 'Connection'

class LocalHost < Connection
  undef_method :authorize!
  undef_method :listen
  undef_method :reconnect
  attr_accessor :access_trier

  def initialize(server)
    @host = 0
    @connected_at = Time.now
    @server = server
    @authorized = true
  end


  def authorized?
    true
  end

  def close
  end

  def post(data)
  end

end