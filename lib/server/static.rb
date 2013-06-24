class D3ObyTCPServer
  module Static

    VERSION = "0.1.0"





    ####################################
    # R E S P O N S E S ################
    RESP_MSG_INVALID = '[msg-invalid]'
    RESP_MSG_FAIL = '[msg-fail]'
    RESP_MSG_SERVED = '[msg-served]'
    RESP_ORDER_FORBIDDEN = '[order-forbidden]'
    RESP_HEAD_INVALID = '[head-invalid]'
    RESP_ROOM_INVALID = '[room-invalid]'
    RESP_ID_INVALID = '[id-invalid]'
    RESP_ID_AUTHORIZE= '[id-auth]'
    RESP_ACC_GRANTED = '[acs-granted]'
    RESP_ACC_DENIED = '[acs-denied]'
    ###################################

    ####################################
    # S E T T I N G S ##################
    SET_OVER_ROOM_REACHABILITY = 0b1
    SET_TRAMP_ACCESS = 0b10
    ###################################

  end
end
