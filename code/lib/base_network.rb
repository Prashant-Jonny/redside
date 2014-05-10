# Super Entity Game Server
# http://segs.nemerle.eu/
# Copyright (c) 2014 Super Entity Game Server Team (see Authors.txt)
# This software is licensed! (See LICENSE for details)

require 'socket'
require_relative 'log'

class BaseNetwork
  MAX_DATA_LENGTH = 512 # maximum number of bytes to send()/recv() at a time

  def recv(socket)
    data = socket.gets().chomp("\r\n")

    if data.length > MAX_DATA_LENGTH
      data = data[0..MAX_DATA_LENGTH - 1]
    end

    return data
    # Handle exception in case socket goes away...
    rescue
      close(socket)
  end

  def send(socket, data)
    if data.length > MAX_DATA_LENGTH
      data = data[0..MAX_DATA_LENGTH - 1]
    end

    socket.write(data + "\x0D\x0A")
    # Handle exception in case socket goes away...
    rescue
      close(socket)
  end

  def close(socket)
    begin
      socket.close()
    rescue => e
      raise e
    ensure
      # any cleanup here
    end
  end
end
