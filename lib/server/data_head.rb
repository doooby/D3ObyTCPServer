
class DataHead
  attr_reader :original, :sender, :as, :key, :receiver, :injunction_id

  def initialize(data)
    @valid = true
    @original = data.dup

    injunction = data.slice! /!\d*$/
    injunction = data.slice! /:\d*$/ if injunction.nil?
    unless injunction.nil?
      @injunction = injunction.slice! 0
      @injunction_id = injunction.to_i
    end

    receiver = data.slice! />.+$/
    receiver = data.slice! /<.+$/ if receiver.nil?
    @sending_side = receiver.slice! 0 unless receiver.nil?
    @receiver = (receiver.nil? ? 's' : receiver)
    @multi_ids = !(@receiver=~/^(\d+,)*\d+$/).nil?
    @valid = false unless @receiver=~/^[shoa]$/ unless @multi_ids

    if data=~/^(\d+)([gh][a-f\d]{8}?)?$/
      @sender = $1.to_i
      if $2.nil?
        @as = ''
      else
        @as = $2.slice! 0
        @key = $2 unless $2.empty?
      end
    else
      @valid = false
    end
  end

  def valid?
    @valid
  end

  def injunction?
    @injunction == '!'
  end

  def response?
    @injunction == ':'
  end

  def foreward?
    @sending_side == '>'
  end

  def backward?
    @sending_side == '<'
  end

  def multi_receivers
    return nil unless @multi_ids
    @receiver.split(',').map{|id| id.to_i}.uniq
  end

  class NewConnectionHead < self
    def initialize(as)
      @valid = true
      @as = as
    end
  end
end