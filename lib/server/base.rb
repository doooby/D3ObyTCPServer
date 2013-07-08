require 'socket'
require_relative 'static'
require_relative 'helper'
require_relative '../access/AccessTrier'

class D3ObyTCPServer
  include D3ObyTCPServer::Static
  include D3ObyTCPServer::Helper

  attr_reader :ip, :port

  def initialize(**args)
    @started = false
    @socket = nil
    @listenning_thread = nil
    @space = VirtualSpace.new self, 5
    set_up args
  end

  def set_up(**args)
    @sett = 0b0

    ### tramp access
    @tramp_access_trier = args[:tramp_access_trier]
    unless @tramp_access_trier.nil?
      raise 'err in set_up: tramp_access_treir is not AccessTrier class nor nil' unless @tramp_access_trier.is_a?(AccessTrier)
      @sett|=SET_TRAMP_ACCESS
    end
    ### remote host access
    @host_access_trier = args[:host_access_trier]
    unless @host_access_trier.nil?
      raise 'err in set_up: host_access_treir is not AccessTrier class nor nil' unless @host_access_trier.is_a?(AccessTrier)
      @sett|=SET_HOST_ACCESS
    end
    ### guest access trier - must be at least default one
    @guest_access_trier = args[:guest_access_trier]
    @guest_access_trier = AccessTrier.new if @guest_access_trier.nil?
    ### možnost posílat zprávy napříč místnostmi
    @set|=SET_OVER_ROOM_REACHABILITY  unless args[:over_room_reachability]


  end

  def start
    return if @started
    puts 'Starting D3ObyTCPServer'
    @ip = 'localhost'
    @port = 151515
    @socket = TCPServer.new @ip, @port
    @socket.setsockopt Socket::SOL_SOCKET, Socket::SO_REUSEADDR, 1
    @started = true
    listen_for_connections
  end

  def stop
    return unless @started
    @listenning_thread.kill if @listenning_thread.alive?
    @space.deatch_all
    @socket.kill
    @listenning_thread.join if @listenning_thread.alive?
    @listenning_thread = nil
    @started = false
  end

  def add_host(host, access_trier)
     #TODO
  end

  def running
    @started
  end

  ######################################################################################################################

  def listen_for_connections
    return unless @started
    if @listenning_thread.nil?
      @listenning_thread = Thread.new do
        Thread.current[:to_wait] = false
        puts 'Server starts to listen for incomming connections.'
        loop do
          begin
            new_conn = @socket.accept
          rescue Errno::EAGAIN, Errno::EWOULDBLOCK, Errno::ECONNABORTED, Errno::EPROTO, Errno::EINTR
            puts 'Incomming connection failed - skipping for next.' #IO.select([@socket])
            retry
          rescue Exception => e
            puts "Fatal error for listenning server socket: #{e.message}."
            @listenning_thread = nil
            listen_for_connections
            Thread.current.kill
          end
          @space.attach new_conn

          Thread.current.stop if Thread.current[:to_wait]
        end
      end
    else
      @listenning_thread[:to_wait] = false
      @listenning_thread.wakeup
    end
  end

  def listenning
    !@listenning_thread.nil? && !@listenning_thread[:to_wait]
  end

  def abort_listenning
    @listenning_thread[:to_wait] = true
  end

  ######################################################################################################################

  def can_over_room_reachability?
    @sett&SET_OVER_ROOM_REACHABILITY > 0
  end
  def can_tramp_access?
    @sett&SET_TRAMP_ACCESS > 0
    end
  def can_host_access?
    @sett&SET_HOST_ACCESS > 0
  end

end
