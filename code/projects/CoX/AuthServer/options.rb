# Super Entity Game Server
# http://segs.nemerle.eu/
# Copyright (c) 2014 Super Entity Game Server Team (see Authors.txt)
# This software is licensed! (See LICENSE for details)

# Load library path
$LOAD_PATH << "../../../lib"

require 'abstract_options'

class Options < AbstractOptions
  def self.listen_address
    return @@listen_address
  end

  def self.listen_port
    return @@listen_port
  end

  def self.io_type
    return @@io_type
  end

  def self.debug_mode
    return @@debug_mode
  end

  def self.parse(options_file)
    begin
      option_params = YAML.load_file(options_file)
    rescue => e
      puts "Unable to open #{options_file}!"
      Log.write(2, "authserver.log", "Unable to open #{options_file}!")
      exit!
    end

    @@listen_address = option_params["listen_address"]
    @@listen_port = option_params["listen_port"]
    @@io_type = option_params["io_type"]
    @@debug_mode = option_params["debug_mode"]

    if @@listen_port == nil || @@listen_port != 2106
      # add some resiliency if they left the port empty or 
      # have it set to something other than 2106...
      @listen_port = 2106
    end

    if @@io_type == nil
      # just use select by default
      @@io_type = "select"
    end

    if @@io_type.to_s == "event"
      puts "I/O type \"event\" is not implemented yet! Using select instead..."
      @@io_type = "select"
    end

    if @@io_type.to_s != "select" && @@io_type.to_s != "thread"
      error_text = "\nio_type value should be set to either event or thread."
      puts "I/O type value should be set to either \"select\" or \"thread\"."
      puts "Please fix the io_type setting in #{options_file}. Using select for now..."
      @@io_type = "select"
    end

    if @@debug_mode == nil || (@@debug_mode.to_s != "true" && @@debug_mode.to_s != "false")
      puts "debug_mode value should be set to either \"true\" or \"false\". Enabling debug mode for this run..."
      @@debug_mode = "true"
    end
  end
end
