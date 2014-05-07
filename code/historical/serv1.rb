require "socket"
require "gserver"
#require "english"
#require "coh_codec"

require_relative "ServerInfo"

#require 'profile';
$packet_error_t = 0;
$server_list = ServerList.new();

class Packet
  def initialize
    @packet_type = 0;
    @packet_length =0;
  end
  def parse(from_buffer)
    return false if(from_buffer.length<2);
    @packet_type,@packet_length = from_buffer.unpack("nc");
    return (@packet_type = from_buffer[2]) < 0xA;
  end;
# used when sending
  def to_s
    [@packet_length,@packet_type].pack("SC"); # n - unsigned short, network order 
  end
  def info
    return "LoginPacket: length=#{@packet_length}, type=#{@packet_type}";
  end
end;
class LoginServerPacket < Packet # this class implements all packets sent by loginserver to the client
  def initialize()
    super
    @contents = "";
  end;
  def to_s
    @packet_length = @contents.length
    return super+@contents; # call default packet building routine packet serialization
            # no changes to packet_contents    
  end;
  def protocol_ver(key,version)
    @packet_type = 0;
    @contents = [key,version].pack("NN"); # two longs in Network byte order
  end;
  def error(error_number,error_reason)
    @packet_type=error_reason; 
    case error_reason
      when "reason1" then @packet_type=1;
      when "reason2" then @packet_type=2;
      when "reason3" then @packet_type=5;
      when "reason4".."reason5" then @packet_type=6;
      else
        puts("Wrong error code: #{error_number} in send_error");
    end;
    @contents = [error_number].pack("c") if (error_number<0x23)
    
  end;
  def serverList()
    @packet_type = 4;
    @contents = $server_list.getPacket();
  end;
  def auth_response(llVar)
    @packet_type = 3;
    @contents = [llVar&0xFFFFFFFF,llVar>>32,0,0,0,0,0].pack("L7");
  end;
  def serverConnect(serv_num)
    @packet_type = 7;
    @contents = [7000,7001,1].pack("L2C");
  end
end;
class LoginClient
  CLIENT_UNCONNECTED =0;
  CLIENT_CONNECTED = 1;
  CLIENT_AUTHORIZED = 2;
  CLIENT_SERVSELECT = 3;
  CLIENT_AWAIT_DISCONNECT = 4;
  def initialize(client_socket,connection_key)  
    @client_socket = client_socket;
    @server_packet = LoginServerPacket.new;
    @client_state  = CLIENT_UNCONNECTED;
    @packet_codec  = Coh_codec::PacketCodec.new;
    @my_key        = connection_key;
    @packet_codec.SetPacketKey(connection_key);
    @packet_err_reason = "reason4";
    @client_stamp = (Time.now.tv_sec)|(Time.now.tv_usec<<32);
  end;
  def run_loop()
    case @client_state
      when CLIENT_CONNECTED 
        @client_resp = @client_socket.recv(3);
        if(@client_resp.length==3)
          plength,ptype = @client_resp.unpack("sc");
          puts "Client_Responds: packet length #{plength}, packet type #{ptype}";        
          
          @client_resp = @client_socket.recv(plength.to_i);
          @client_resp.unpack("C*").each {|c| printf("0x%02x.",c)}
          # decode only pass/login part
          @packet_codec.LoginDecode(@client_resp,@client_resp.length-6);
          @packet_codec.Decode(@client_resp,@client_resp.length);
          
          login,password,par1,par2 = @client_resp.unpack("A13@14A13LS")
          puts "Auth: Login:"+login;
          puts "Auth: Password:"+password+" Params:"+par1.to_s+","+par2.to_s;
          @client_resp = "";
          @server_packet.auth_response(@client_stamp);
          @client_socket.send(@server_packet.to_s,0);
#          puts "Sending to client:"
#          @server_packet.to_s.unpack("C*").each {|c| printf("0x%02x.",c)}
#          printf("\n");
          @client_state=CLIENT_AUTHORIZED;
        end;
      when CLIENT_AUTHORIZED 
        @client_resp = @client_socket.recv(3);
        if(@client_resp.length==3)        
          plength,ptype = @client_resp.unpack("sc");
          puts "Client_Responds: packet length #{plength}, packet type #{ptype}";
          @client_resp = @client_socket.recv(plength.to_i);
          @client_resp.unpack("C*").each {|c| printf("0x%02x.",c)}
          @server_packet.serverList();
#          @server_packet.error($packet_error_t,@packet_err_reason);
#          puts "Sent error:"+@packet_err_reason+" "+$packet_error_t.to_s 
#          $packet_error_t+=1;
          @client_socket.send(@server_packet.to_s,0);
      #   puts "Sending to client:"
      #    @server_packet.to_s.unpack("C*").each {|c| printf("0x%02x.",c)}
          @client_state = CLIENT_SERVSELECT;
          return 1;
        end;
 #       puts "Authorized client\n";
      when CLIENT_UNCONNECTED 
        @server_packet.protocol_ver(0,1);
        @client_socket.send(@server_packet.to_s,0);
        @client_state=CLIENT_CONNECTED;
      when CLIENT_SERVSELECT
        @client_resp = @client_socket.recv(3)
        plength,ptype = @client_resp.unpack("sc");
        if(@client_resp.length==3)        
          @client_resp = @client_socket.recv(plength.to_i);
          t_arr = @client_resp.unpack("LLC")
          puts "Connect to server num:"+t_arr[2].to_s
          @server_packet.serverConnect(t_arr[2]);
          @client_socket.send(@server_packet.to_s,0);
          @client_state = CLIENT_AWAIT_DISCONNECT;
        end
      when CLIENT_AWAIT_DISCONNECT
        sleep 25.0  ; #sleep a little
        return 0; # and disconnect
      else
        @client_resp = @client_socket.recv(3)
        plength,ptype = @client_resp.unpack("sc");
        puts "Unkn packet: packet length #{plength}, packet type #{ptype}";
        return 0
    end;
    sleep 0.05;
    return 1;
  end;
end;
class LoginServer < GServer
  def initialize(port=2106,*args)
    super(port,*args);
    
  end;
  def serve(client_socket)
    begin
      puts "serve1"
      login_client = LoginClient.new(client_socket,0);    
      while(login_client.run_loop()==1)
      end;
    rescue Exception
      puts $!;
    end;
    puts "Loop end\n";
  end;
end;
class GameServer
  
  DEFAULT_HOST = "127.0.0.1"
  def initialize(port, host = DEFAULT_HOST, maxConnections = 4,
    stdlog = $stderr, audit = false, debug = false)
    @udpServerThread = nil;
    @udpPort = port;
    @stdlog = stdlog
    @audit = audit
    @debug = debug
    @host = host;
    @server = UDPSocket.open();
  end;
  def join
    @udpServerThread.join if @udpServerThread
  end
  def begin_serv()
    @server.bind(@host, @udpPort); #listen port
    log("#{self.class.to_s} UDP:#{@host}:#{@udpPort} start")
    @udpServerThread = Thread.start do     # run server in a thread
      puts "Server at:#{@udpPort} is waiting on data.\n"
      while 1
        begin
          @client_resp = @server.recvfrom(64);
          puts "G got a packet from #{@client_resp[1][2]}/#{@client_resp[1][3]}:#{@client_resp[1][1]}"
          @client_resp[0].unpack("C*").each {|c| printf("0x%02x.",c) }
          puts "\n"
          sleep 0.01;
        rescue Exception
          puts $!;
          raise;
        end
      end;
    end;
  end
  def log(msg)
    if @stdlog
      @stdlog.puts("[#{Time.new.ctime}] %s" % msg)
      @stdlog.flush
    end
  end  
  protected :log
end;
SERVER_BOUND_AT = "172.16.0.46"
t = ServerInfo.new(SERVER_BOUND_AT,8765,"noname");
$server_list.addServ(t);
t = ServerInfo.new(SERVER_BOUND_AT,8766,"noname");
$server_list.addServ(t);

gserver = GameServer.new(8765,SERVER_BOUND_AT);
gserver.begin_serv();
gserver1 = GameServer.new(7000);
gserver1.begin_serv();
gserver2 = GameServer.new(7001);
gserver2.begin_serv();

server = LoginServer.new(2106,SERVER_BOUND_AT);
server.audit = true;
server.debug = true;
server.start();
server.join()

gserver.join()
gserver1.join()
gserver2.join()