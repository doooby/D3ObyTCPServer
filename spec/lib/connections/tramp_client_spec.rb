require 'spec_helper'

describe 'Tramp client' do

  before :all do
    @server = D3ObyTCPServer.new(
        tramp_access_trier: AccessTrier.new,
        can_send_to_all: true
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

  it 'logg in as tramp' do
    count = @server.space.count
    socket = nil
    lambda{socket = connect_socket}.should_not raise_error
    sleep 0.1
    @server.space.count.should == count+1
    logg_in_as_tramp socket
  end

  it "sends 'hello' to another tramp" do
    #first tramp
    first_socket = connect_socket
    first_id = logg_in_as_tramp first_socket
    #second tramp
    second_socket = connect_socket
    second_id = logg_in_as_tramp second_socket
    #send greets
    greets = 'Hello there!'
    first_socket.puts "[#{first_id}>#{second_id}]#{greets}"
    receive_msg_from second_socket, first_id, '-1', greets
  end

  it "sends 'hello' to thwo other tramps" do
    #first tramp
    first_socket = connect_socket
    first_id = logg_in_as_tramp first_socket
    #second tramp
    second_socket = connect_socket
    second_id = logg_in_as_tramp second_socket
    #third tramp
    third_socket = connect_socket
    third_id = logg_in_as_tramp third_socket
    #send greets
    greets = 'Hello there!'
    first_socket.puts "[#{first_id}>#{second_id},#{third_id}]#{greets}"
    receive_msg_from second_socket, first_id, '-1', greets
    receive_msg_from third_socket, first_id, '-1', greets
  end

  it "sends 'hello' to all tramps" do
    #first tramp
    first_socket = connect_socket
    first_id = logg_in_as_tramp first_socket
    #second tramp
    second_socket = connect_socket
    logg_in_as_tramp second_socket
    #third tramp
    third_socket = connect_socket
    logg_in_as_tramp third_socket
    #send greets
    greets = 'Hello there!'
    first_socket.puts "[#{first_id}>a]#{greets}"
    receive_msg_from second_socket, first_id, '-1', greets
    receive_msg_from third_socket, first_id, '-1', greets
  end
end