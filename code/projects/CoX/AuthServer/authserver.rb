# Super Entity Game Server
# http://segs.nemerle.eu/
# Copyright (c) 2014 Super Entity Game Server Team (see Authors.txt)
# This software is licensed! (See LICENSE for details)

if RUBY_VERSION < "1.9"
  puts "SEGS/RedSide requires Ruby >=1.9!"
  exit!
end

# Load library path
$LOAD_PATH << "../../../lib"

require 'log'
require 'segs'
require_relative 'network'
require_relative 'options'

puts "#{SEGS::VERSION}"
puts "#{SEGS::RELEASE}"
puts "#{SEGS::URL}\n\n"
puts "Starting AuthServer..."
Log.write(0, "authserver.log", "Starting AuthServer...")
puts "Parsing authserver.yml..."
Log.write(0, "authserver.log", "Parsing authserver.yml...")
Options.parse("config/authserver.yml")
puts "Initializing network..."
Log.write(0, "authserver.log", "Initializing network...")
Network.start()
