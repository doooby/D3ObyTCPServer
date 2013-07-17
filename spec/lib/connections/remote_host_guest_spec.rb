require 'spec_helper'

describe 'Remote Host' do

  before :all do
    @server = D3ObyTCPServer.new(
        host_access_trier: AccessTrier.new
    )
    @server.start
  end

  after :all do
    @server.stop
  end

  after :each do
    @server.space.dettach_all
  end

  ######################################################################################################################

  it 'creates a room' do
    count = @server.space.count
    socket = nil
    lambda{socket = connect_socket}.should_not raise_error
    sleep 0.1
    @server.space.count.should == count+1
    logg_in_as_host socket
  end

  it 'let guests join' do
    pending 'not implemented'
    #host_socket = nil
    #lambda{host_socket = connect_socket}.should_not raise_error
    #host_id = logg_in_as_host host_socket
    #guest_socket = nil
    #lambda{guest_socket = connect_socket}.should_not raise_error
    #logg_in_as_guest guest_socket, host_id
  end
end