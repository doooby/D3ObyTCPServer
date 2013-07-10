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

  def connect_socket
    TCPSocket.new @server.ip, @server.port
  end

  def logg_in_as_tramp(socket)
    socket.puts '[]'
    socket.gets.strip
  end

  ######################################################################################################################

  it 'connects' do
    lambda{connect_socket}.should_not raise_error
  end

  it 'logg in as tramp' do
    socket = connect_socket
    logg_in_as_tramp(socket).match /^\[(.*)\](\d+)$/
    $1.should eql D3ObyTCPServer::Static::RESP_ACC_GRANTED[1..-2]
    $2.should_not be_nil
  end

  it "sends 'hello' to second tramp" do
    #first tramp
    first_socket = connect_socket
    logg_in_as_tramp(first_socket).match /\[(.+)\](\d+)/
    $1.should eql D3ObyTCPServer::Static::RESP_ACC_GRANTED[1..-2]
    $2.should_not be_nil
    first_id = $2.to_i
    #second tramp
    second_socket = connect_socket
    logg_in_as_tramp(second_socket).match /\[(.+)\](\d+)/
    $1.should eql D3ObyTCPServer::Static::RESP_ACC_GRANTED[1..-2]
    $2.should_not be_nil
    second_id = $2.to_i
    #send greets
    first_socket.puts "[#{first_id}|#{second_id}]Hello there!"
    result = nil
    lambda{Timeout::timeout(3){result = first_socket.gets.strip}}.should_not raise_error
    result.should eql D3ObyTCPServer::Static::RESP_MSG_SERVED
    lambda{Timeout::timeout(3){result = second_socket.gets.strip}}.should_not raise_error
    result.match /^\[(\d*),(-?\d*)\](.+)/
    $1.to_i.should eql first_id
    $2.to_i.should eql -1
    $3.should eql 'Hello there!'
  end

  it "sends 'hello' to all tramps" do
    #first tramp
    first_socket = connect_socket
    logg_in_as_tramp(first_socket).match /\[(.+)\](\d+)/
    $1.should eql D3ObyTCPServer::Static::RESP_ACC_GRANTED[1..-2]
    $2.should_not be_nil
    first_id = $2.to_i
    #second tramp
    second_socket = connect_socket
    logg_in_as_tramp(second_socket).match /\[(.+)\](\d+)/
    $1.should eql D3ObyTCPServer::Static::RESP_ACC_GRANTED[1..-2]
    $2.should_not be_nil
    #third tramp
    third_socket = connect_socket
    logg_in_as_tramp(third_socket).match /\[(.+)\](\d+)/
    $1.should eql D3ObyTCPServer::Static::RESP_ACC_GRANTED[1..-2]
    $2.should_not be_nil
    #send greets
    first_socket.puts "[#{first_id}|a]Hello there!"
    result = nil
    lambda{Timeout::timeout(3){result = first_socket.gets.strip}}.should_not raise_error
    result.should eql D3ObyTCPServer::Static::RESP_MSG_SERVED
    lambda{Timeout::timeout(3){result = second_socket.gets.strip}}.should_not raise_error
    result.match /^\[(\d*),(-?\d*)\](.+)/
    $1.to_i.should eql first_id
    $2.to_i.should eql -1
    $3.should eql 'Hello there!'
    lambda{Timeout::timeout(3){result = third_socket.gets.strip}}.should_not raise_error
    result.match /^\[(\d*),(-?\d*)\](.+)/
    $1.to_i.should eql first_id
    $2.to_i.should eql -1
    $3.should eql 'Hello there!'
  end
end