require 'securerandom'

class D3ObyTCPServer
  include D3ObyTCPServer::Settings
  include D3ObyTCPServer::Callbacks

  attr_reader :ip, :port, :logger, :space
  attr_reader :tramp_access_trier, :host_access_trier

  def initialize(**args)
    @logger = D3ObyTCPServer::Logger.new
    @logger.info 'Starting D3ObyTCPServer'
    set_up args
    @started = @listener.listenning?
  end

  def stop
    return unless @started
    @started = false
    @listener.destroy if @listener
    @space.each_conn &:disconnect
  end

  def running?
    @started
  end

  ##############################

  def self.generate_access_key
    SecureRandom.hex 4
  end
end
