module D3ObyTCPServer::Settings

  def set_up(**args)
    @sett = 0b0

    ## IP
    @ip = args[:ip]
    @ip = 'localhost' unless @ip
    ## PORT
    @port = args[:port]
    @port = '151515' unless @port

    ## Virtual space
    @space = VirtualSpace.new self, args[:max_connections]

    ## listener
    @listener = D3ObyTCPServer::Listener.new self

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

    ### možnost posílat zprávy všem
    @sett|=SET_CAN_SEND_TO_ALL  if args[:can_send_to_all]

    ### možnost posílat zprávy napříč místnostmi
    @sett|=SET_OVER_ROOM_REACHABILITY  if args[:over_room_reachability]

  end

  ######################################################################################################################

  SET_CAN_SEND_TO_ALL = 0b1
  SET_OVER_ROOM_REACHABILITY = 0b10
  SET_TRAMP_ACCESS = 0b100
  SET_HOST_ACCESS = 0b1000

  def can_send_to_all?
    @sett&SET_CAN_SEND_TO_ALL > 0
  end
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
