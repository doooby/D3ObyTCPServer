#require 'rubygems'
#require 'bundler/setup'
require "#{Dir.getwd}/lib/d3oby_tcp_server.rb"
require 'rspec'
require 'timeout'

RSpec.configure do |config|
  # some (optional) config here
end

########################################################################################################################
# C O N N E C T   &   L O G G   I N
########################################################################################################################
def connect_socket
  TCPSocket.new @server.ip, @server.port
end

def logg_in_as_tramp(socket)
  socket.puts '[]'
  resp = nil
  lambda {
    Timeout::timeout(3) do
      resp = socket.gets.strip
    end
  }.should_not raise_error
  resp = resp.split('|')
  resp.shift.should == D3ObyTCPServer::Static::RESP_ACC_GRANTED
  resp[0].should_not be_nil
  resp[0].to_i
end

def logg_in_as_host(socket)
  socket.puts '[h]'
  resp = nil
  lambda {
    Timeout::timeout(3) do
      resp = socket.gets.strip
    end
  }.should_not raise_error
  resp = resp.split('|')
  resp.shift.should == D3ObyTCPServer::Static::RESP_ACC_GRANTED
  resp[0].should_not be_nil
  resp[1].should_not be_nil
  [resp[0].to_i, resp[1]]
end

def attach_local_host(server, &on_receive_block)
  host = LocalHost.new server, &on_receive_block
  host.access_trier = AccessTrier.new
  server.space.attach_local_host host
  host
end

def logg_in_as_guest(socket, host_id)
  socket.puts "[g#{host_id}]"
  resp = nil
  lambda {
    Timeout::timeout(3) do
      resp = socket.gets.strip
    end
  }.should_not raise_error
  resp = resp.split('|')
  resp.shift.should == D3ObyTCPServer::Static::RESP_ACC_GRANTED
  resp[0].should_not be_nil
  resp[1].should_not be_nil
  [resp[0].to_i, resp[1]]
end

def reconnect(socket, id, host, key)
  socket.puts "[r]#{id}|#{host}|#{key}"
  resp = nil
  lambda {
    Timeout::timeout(3) do
      resp = socket.gets.strip
    end
  }.should_not raise_error
  resp.should == D3ObyTCPServer::Static::RESP_ACC_GRANTED
end

########################################################################################################################
# S E N D I N G
########################################################################################################################
def receive_msg(socket)
  resp = nil
  lambda {
    Timeout::timeout(3) do
      resp = socket.gets.strip
    end
  }.should_not raise_error
  resp
end

def receive_msg_from(socket, from, his_host, msg)
  resp = nil
  lambda {
    Timeout::timeout(3) do
      resp = socket.gets.strip
      resp.slice! /^\[(\d+)\|(-1|\d+)\]/
    end
  }.should_not raise_error
  $1.to_i.should == from
  $2.should == his_host
  resp.force_encoding('utf-8').should == msg
end

def send_and_get_served_response(socket, message)
  raise 'Not implemented'
  #socket.puts message
  #res = nil
  #lambda {
  #  Timeout::timeout(3) do
  #    res = socket.gets.strip
  #  end
  #}.should_not raise_error
  #res.should eql D3ObyTCPServer::Static::RESP_MSG_SERVED
end

def post_and_receive(socket, data)
  raise 'Not implemented'
  #socket.puts data
  #resp = nil
  #lambda {
  #  Timeout::timeout(3) do
  #    resp = socket.gets.strip
  #  end
  #}.should_not raise_error
  #resp
end

