require 'spec_helper'
require 'timeout'

describe 'Tramp client' do

  before :all do
    @server = D3ObyTCPServer.new(
        tramp_access_trier: AccessTrier.new
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
    socket = nil
    lambda{socket = connect_socket}.should_not raise_error
    logg_in_as_tramp socket
  end

  it "sends 'hello' to second tramp" do
    ##first tramp
    #first_socket = connect_socket
    #first_id = logg_in_as_tramp first_socket
    ##second tramp
    #second_socket = connect_socket
    #second_id = logg_in_as_tramp second_socket
    ##send greets
    #greets = 'Hello there!'
    #send_and_get_served_response first_socket, "[#{first_id}|#{second_id}]#{greets}"
    #receive_message(second_socket, first_id, -1).should eql greets
  end

  it "sends 'hello' to all tramps" do
    ##first tramp
    #first_socket = connect_socket
    #first_id = logg_in_as_tramp first_socket
    ##second tramp
    #second_socket = connect_socket
    #logg_in_as_tramp second_socket
    ##third tramp
    #third_socket = connect_socket
    #logg_in_as_tramp third_socket
    ##send greets
    #greets = 'Hello there!'
    #send_and_get_served_response first_socket, "[#{first_id}|a]#{greets}"
    #receive_message(second_socket, first_id, -1).should eql greets
    #receive_message(third_socket, first_id, -1).should eql greets
  end
end