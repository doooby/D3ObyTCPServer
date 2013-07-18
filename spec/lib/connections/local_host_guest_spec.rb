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

  it 'lets guests join' do
    host = attach_local_host @server
    guest_socket = nil
    lambda{guest_socket = connect_socket}.should_not raise_error
    id, key = logg_in_as_guest guest_socket, host.id
  end

  it 'receives from a guest' do
    @host_res = nil
    host = attach_local_host(@server) {|data|@host_res = data}
    guest_socket = nil
    lambda{guest_socket = connect_socket}.should_not raise_error
    id, key = logg_in_as_guest guest_socket, host.id
    guest_socket.puts "[#{id}g>h]'brý den"
    sleep 0.1
    @host_res.should == "[#{id}|#{host.id}]'brý den"
  end

  it 'sends to all guests' do
    host = attach_local_host(@server)
    guest1_socket = nil
    lambda{guest1_socket = connect_socket}.should_not raise_error
    logg_in_as_guest guest1_socket, host.id
    guest2_socket = nil
    lambda{guest2_socket = connect_socket}.should_not raise_error
    logg_in_as_guest guest2_socket, host.id
    host.resp "[#{host.id}>o]košilečku vila"
    receive_msg_from guest1_socket, host.id, '0', 'košilečku vila'
    receive_msg_from guest2_socket, host.id, '0', 'košilečku vila'
  end

  it 'communicates with guest even after its reconnection' do
    @host_res = nil
    host = attach_local_host(@server) {|data| @host_res = data}
    guest_socket = nil
    lambda{guest_socket = connect_socket}.should_not raise_error
    id, key = logg_in_as_guest guest_socket, host.id
    guest_socket.close
    sleep 0.1
    lambda{guest_socket = connect_socket}.should_not raise_error
    reconnect guest_socket, id, host.id, key
    guest_socket.puts "[#{id}g>h]'brý den"
    sleep 0.1
    @host_res.should == "[#{id}|#{host.id}]'brý den"
    host.resp "[#{host.id}>#{id}]košilečku vila"
    receive_msg_from guest_socket, host.id, '0', 'košilečku vila'
  end

end