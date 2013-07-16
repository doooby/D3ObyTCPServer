require 'socket'
require 'thread'
require_relative 'base'
require_relative 'msg_processor'

class D3ObyTCPServer
  attr_reader :space

  def internal_injuction(order, conn=nil)
    puts "\tINTERNAL ORDER: #{order}"
    #
    ##---------------------------------
    #if order.match /^kill_conn (\d*)$/
    #  who = $1.to_i
    #  if conn.nil?
    #    raise 'Not implemented yet IN Server#internal_order - kill_conn - without conn'
    #  else
    #    if who==conn.id
    #      @space.dettach conn.id
    #      true
    #    elsif conn.host==0
    #      if conn.room.guest? who.id
    #        @space.dettach who.id
    #        true
    #      else
    #        return false, "cannot kill guest when you are not hosting"
    #      end
    #    else
    #      return false, "cannot kill others (only if you are guests)"
    #    end
    #  end
    ##---------------------------------
    #elsif true
    #  return false, 'unknown command'
    #end
    false
  end

end