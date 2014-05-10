# Super Entity Game Server
# http://segs.nemerle.eu/
# Copyright (c) 2014 Super Entity Game Server Team (see Authors.txt)
# This software is licensed! (See LICENSE for details)

# Load library path
$LOAD_PATH << "../../../lib"

require 'base_network'
require 'log'
require_relative 'options'

class Network < BaseNetwork
  def self.start()
    begin
      if Options.listen_address != nil
        server_socket = TCPServer.new(Options.listen_address, Options.listen_port)
      else
        server_socket = TCPServer.new(Options.listen_port)
      end
    rescue Errno::EADDRNOTAVAIL => e
      puts("Invalid listen_address: #{Options.listen_address}")
      Log.write(2, "Invalid listen_address: #{Options.listen_address}")
      Log.write(e)
      exit!
    rescue SocketError => e
      puts("Invalid listen_address: #{Options.listen_address}")
      Log.write(2, "Invalid listen_host: #{Options.listen_address}")
      Log.write(e)
      exit!
    rescue => e
      puts("Unable to listen on TCP port: #{Options.listen_port}")
      Log.write(2, "Unable to listen on TCP port: #{Options.listen_port}")
      Log.write(e)
      exit!
    end

    # ToDo: Add EventMachine support
    if Options.io_type.to_s == "thread"
      server_thread = Thread.new() { handle_threaded_connections(server_socket) }
      server_thread.join()
    else
      handle_select_connections(server_socket)
    end
  end

  def self.handle_select_connections(server_socket)
    loop do
      socket = select([server_socket])
      socket.each do |sock|
        if sock == server_socket
          client = server_socket.accept_nonblock()
          send(client, "Go ahead with transmission, hero.")
          # Handle packets here
        end
      end
    end
    rescue SocketError => e
      puts "Open file descriptor limit reached!"
      Log.write(1, "Open file descriptor limit reached!") # we likely cannot write to the log file in this state, but try anyway...
  end

  def self.handle_threaded_connections(server_socket)
    loop do
      Thread.start(server_socket.accept()) do |client|
        send(client, "Go ahead with transmission, hero.")
        # Handle packets here
      end
    end
    rescue SocketError => e
      puts "Open file descriptor limit reached!"
      Log.write(1, "Open file descriptor limit reached!") # we likely cannot write to the log file in this state, but try anyway...
  end
end
