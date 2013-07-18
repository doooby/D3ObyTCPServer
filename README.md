# D3ObyTCPServer

A simple TCP server made into a ruby gem.

## Installation

Gem name:

    gem 'd3oby_tcp_server'

## Usage

(still in developement)

The head of a message must has a form:
```ruby
#client to server
'[]'    #logg in as a tramp
'[h]'   #logg in as a host of a room
'[g15]' #logg in as host into the room 15 (host's id)

'[1>2]msg'      #msg as tramp client 1 (only secondary identification purpouse) to client 2
'[3h>22]msg'    #h is neccessary - otherwise won't be served; client is a host
'[2g>22]msg'    #g is neccessary - otherwise won't be served; client is a guest
'[1>2,15,3]msg' #msg to clients 2,15,3
'[1>s]msg'      #msg to server (internal - not used yet)
'[2g>h]msg'      #msg to host of room (only works within the room)
'[2g>o]msg'      #msg to all other guests within the room (not self neither host)
'[1>a]msg'      #msg to all. aply can_send_to_all and over_room_reachability settings here

#from server to client
'[1|-1]msg' #msg from a tramp with id 1 
'[2|0]msg'  #msg from a host with id 2 
'[3|2]msg'  #msg from a guest with id 1 from room 2
```

###1)Tramp-only server (v0.2)
Run a server as it is within the gem. Though you may wanth to customize the trier by inheriting from a AccessTrier class.
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
response = socket.gets # '[12|-1]Hello? Who are you?'
response = socket.gets # '[16|-1]What do you wnath, Garry? I am bussy..'
response = socket.gets # '[5|-1]I can hear you! Can you hear me?'
```

###2)Remote-hosted server (since v0.3)
Run a server as it is within the gem. Though you may wanth to customize a trier by inheriting from a AccessTrier class.
```ruby
server = D3ObyTCPServer.new host_access_trier: AccessTrier.new
server.start
```
On client you need to implement a tcp socket with a-like client and a host logic. Guest connection is processed by a remote host via ijuncted communication. The convenience of this approach is that all host-guest logic is implemented at your own, what may be a whatever application with whatever technology supporting TCP/IP Sockets.
####a) Host-client and other clients:
(A ruby example what would a chat a-like app look like inside)
```ruby
host_socket = TCPSocket.new ip, port
host_socket.puts '[h]' #logg in
response, host_id, host_key = host_socket.gets.split '|' #host_id = 3
host_socket.puts '[3h>o]' #every other
#...
client_socket.puts '[4g>o]' #every other guest
client_socket.puts '[4g>h]' #and to host - since he is just another client
```
####b) Host as a stand-alone entity:
In this case, the stan-alone host needs to implement some custom logic of responding to requests. Intedet as a processing point for anything desired from a host.
(A ruby example)
```ruby
host_socket = TCPSocket.new ip, port
host_socket.puts '[h]' #logg in
response, host_id, host_key = host_socket.gets.split '|' #host_id = 3
#...
client1_socket.puts '[g3]' #logg in as a guest of host with id 3
response, client1_id, client1_key = client1_socket.gets.split '|' #client1_id = 5
client1_socket.puts '[5g>h]Hi everyone!'
#... 
host_sokcet.gets # '[5|3]Hi everyone!'
#    given host simply resends it to all guests:
host_socket.puts '[3h>o]Hi everyone!'
#... 
#    everybody within the same room (same host) gets this:
#'[3|0]Hi everyone!'
```

###3)Local-hosted server (v0.2)
In this scenario, host is a custom implemented class on the server side (derived from a LocalHost). The thing is, that that server do not resends communication to and from host via socket, but processes it directly. Local host has to implement the same receiving head format though. Such a host can be attached to the server like this:
```ruby
server.space.attach_local_host host #and guests can logg in to that hosted room
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
