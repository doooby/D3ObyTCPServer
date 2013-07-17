#require 'rubygems'
#require 'bundler/setup'
require "#{Dir.getwd}/lib/d3oby_tcp_server.rb"
require 'rspec'

RSpec.configure do |config|
  # some (optional) config here
end

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
  resp.map{|val| val.to_i}
end

def post_and_receive(socket, data)
  #socket.puts data
  #resp = nil
  #lambda {
  #  Timeout::timeout(3) do
  #    resp = socket.gets.strip
  #  end
  #}.should_not raise_error
  #resp
end

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
  resp.should == msg
end

def send_and_get_served_response(socket, message)
  raise 'Not implemented yet'
  #socket.puts message
  #res = nil
  #lambda {
  #  Timeout::timeout(3) do
  #    res = socket.gets.strip
  #  end
  #}.should_not raise_error
  #res.should eql D3ObyTCPServer::Static::RESP_MSG_SERVED
end

