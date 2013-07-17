require 'spec_helper'

describe 'Local Host' do

  before :all do
    @server = D3ObyTCPServer.new
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
    host = attach_local_host @server
    host.id.should_not be_nil
    @server.space.count.should == count+1
  end

  it 'let guests join' do
    host = attach_local_host @server
    guest_socket = nil
    lambda{guest_socket = connect_socket}.should_not raise_error
    id, key = logg_in_as_guest guest_socket, host.id
    id.should_not be_nil
    key.should_not be_nil
  end
end