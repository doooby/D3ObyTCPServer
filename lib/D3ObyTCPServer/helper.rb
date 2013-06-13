module D30byTCPServer::Helper
  require 'securerandom'

  def access_key
    SecureRandom.hex 4
  end

end