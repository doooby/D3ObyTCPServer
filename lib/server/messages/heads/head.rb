class Messages::Head
  attr_reader :conn, :server

  def initialize(connection)
    @connection = connection
  end

  def valid_format?
    false
  end
end