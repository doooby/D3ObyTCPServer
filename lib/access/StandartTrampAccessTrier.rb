require_relative 'AccessTrier'

class StandartTrampAccessTrier < AccessTrier

  def initialize(max=5)
    super max
  end

  def access(conn, data)
    if full?
      return false, 'Too much tramp clients already connected.'
    else
      @clients+=1
      true
    end
  end
end