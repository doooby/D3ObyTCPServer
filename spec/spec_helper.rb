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
  lambda {
    Timeout::timeout(3) do
      socket.gets.strip.match /^([^\|]+)\|(\d+)$/
    end
  }.should_not raise_error
  $1.should eql D3ObyTCPServer::Static::RESP_ACC_GRANTED
  $2.should_not be_nil
  $2.to_i
end

def logg_in_as_host(socket)
  #socket.puts '[h]'
  #lambda {
  #  Timeout::timeout(3) do
  #    socket.gets.strip.match /^\[(.+)\](\d+\|\d+)?$/
  #  end
  #}.should_not raise_error
  #$1.should eql D3ObyTCPServer::Static::RESP_ACC_GRANTED[1..-2]
  #$2.should_not be_nil
  #$2
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

