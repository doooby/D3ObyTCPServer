class D3ObyTCPServer
  module Static

    VERSION = "0.2"





    ####################################
    # R E S P O N S E S ################
    RESP_HEAD_INVALID = 'head-invalid'

    RESP_ACC_GRANTED = 'acs-granted'
    RESP_ACC_DENIED = 'acs-denied'

    RESP_ID_INVALID = 'id-invalid'

    RESP_SERV_INJ_DONE = 'server-injunction-done'
    RESP_SERV_INJ_FAIL = 'server-injunction-fail'

    RESP_MSG_FAIL = 'msg-fail'
    RESP_MSG_SERVED = 'msg-served'


    #RESP_MSG_INVALID = '[msg-invalid]'

    #RESP_ORDER_FORBIDDEN = '[order-forbidden]'
    #RESP_HEAD_INVALID = '[head-invalid]'
    #RESP_ROOM_INVALID = '[room-invalid]'
    #RESP_ID_INVALID = '[id-invalid]'
    #RESP_ID_AUTHORIZE= '[id-auth]'

    ###################################

    ####################################
    # S E T T I N G S ##################
    SET_CAN_SEND_TO_ALL = 0b1
    SET_OVER_ROOM_REACHABILITY = 0b10
    SET_TRAMP_ACCESS = 0b100
    SET_HOST_ACCESS = 0b1000
    ###################################

  end
end
