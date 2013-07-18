# D3ObyTCPServer

A simple TCP server made into ruby gem.

## Installation

Add this line to your application's Gemfile:

    gem 'D3ObyTCPServer'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install D3ObyTCPServer

## Usage

(still in developement)

###Tramp-only server (v0.2)
Run a server as it is within a gem. Though you may wanth to customize a trier by inheriting from a AccessTrier class.
```ruby
server = D3ObyTCPServer.new tramp_access_trier: AccessTrier.new
server.start
```
A client can simply connect and send messages to another tramps using their id:
(A ruby example)
```ruby
socket = TCPSocket.new ip, port
socket.puts '[]'
response = socket.gets.split '|'
if response[0] == 'acs-granted'
    id = response[1].to_i
    #send hello to tramps with id 12 and 15
    socket.puts "[#{id}>12,15]Hello there!"
    response = socket.gets #will be like: '[12|-1]Hi! How are you?'
    socket.puts "[#{id}>12]I am fine and you?"
else
    #access not granted
end
```
You can set your server to allow 'can_send_to_all' for tramps could send messages to all others..
```ruby
#for server:
server.set_up can_send_to_all: true

#client in ruby code
# ...
socket.puts "[#{id}>a]Can anybody hear me?"
response = socket.gets # '[12|-]Hello? Who are you?'
response = socket.gets # '[16|-]What do you wnath, Garry? I am bussy..'
response = socket.gets # '[5|-]I can hear you! Can you hear me?'
```

###Remote-hosted server (since v0.3)
Run a server as it is within a gem. Though you may wanth to customize a trier by inheriting from a AccessTrier class.
```ruby
server = D3ObyTCPServer.new host_access_trier: AccessTrier.new
server.start
```
On client you need to implement a tcp socket with a-like client and a host logic. Guest connection is processed by a remote host via ijuncted communication. The convenience of this approach is that all host-guest logic is implemented at your own, what may be a whatever application with whatever technology supporting TCP/IP Sockets.
####1) Hosting client and clients:
(A ruby example)
```ruby

```
####2) Host as a stand-alone entity:
In this case, the stan-alone host (aka a separate room with guests in it) needs to implement some custom logic of responding for requests. Intedet as a processing point for resending message to all guests within room or anything else.
(A ruby example what would a chat a-like app look like)
```ruby
host_socket = TCPSocket.new ip, port
host_socket.puts '[h]' #logg in
response, host_id, host_key = host_socket.gets.split '|' #host_id = 3
#...
client1_socket.puts '[g3]' #logg in as a guest of host with id 3
response, client1_id, client1_key = client1_socket.gets.split '|' #client1_id = 5
client1_socket.puts '[5>h]Hi everyone!'
#... 
host_sokcet.gets # '[5|3]Hi everyone!'
#    given host simply resends it to all guests
host_socket.puts '[3>o]Hi everyone!'
#... 
#    everybody within the same room (same host)
#'[3|0]Hi everyone!'
```

###Local-hosted server (v0.2)

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
