class D3ObyTCPServer
  module Helper
    require 'securerandom'

    def generate_access_key
      SecureRandom.hex 4
    end

  end
end