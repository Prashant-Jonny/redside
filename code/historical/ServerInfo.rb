require "socket";

class ServerInfo
  @@c_ServNumber=1;
  def initialize(serv_ip,serv_port,serv_name)
    @i_ServNumber = @@c_ServNumber;
    @@c_ServNumber+=1;
    @i_Serv_name = serv_name;
    @i_Orig_address = serv_ip;

    # split addr on dots, pack result as 4 bytes
    @i_ServIp = 0;
    # wrong order, fixed by sending in N format instead of L
    IPSocket.getaddress(serv_ip).split(".").each() { |i|
      @i_ServIp <<= 8;
      @i_ServIp+=i.to_i;
      #shift -=8;
      #t<<=i.to_i;
    }
#    @i_ServIp = t.pack("CCCC")
    @i_ServPort = serv_port;
    # prepare packet string
    #@i_ServString = [@i_ServNumber,@i_ServIp,@i_ServPort,0,0,0,0,0,0].pack("CLLCCSSC");
    @i_ServString = [@i_ServNumber,@i_ServIp,@i_ServPort,@i_ServNumber,@i_ServNumber,1,10,@i_ServNumber].pack("CNLCCSSC");
  end;
  def to_s()
    return "Server:"+@i_Serv_name+"-"+@i_Orig_address;
  end
  def getPacket
    return @i_ServString;
  end;
end;
class ServerList
  def initialize()
    @i_Servers = Array.new;
    @i_Prefered = 1;
  end;
  def addServ(server_object)
    raise "Wrong type for addServ" if(!(server_object.kind_of?(ServerInfo)));
    raise "Too many servers"       if(@i_Servers.length>255);
    @i_Servers.push(server_object);
    return @i_Servers.length;
  end;
  def remServ(server_index)
    if(!(server_object.kind_of?(Integer)))
      raise "Wrong type for remServ expected:Integer got #{server_object.class}";
    end;
    @i_Servers.delete_at(server_index);
  end
  def getServ(server_index)
    return @i_Servers[server_index];
  end;
  def getPacket()
    res = [@i_Servers.length,@i_Prefered].pack("CC");
    0.upto(@i_Servers.length-1) { |i|
      res+=@i_Servers[i].getPacket();
    }
    return res;
  end;
end;
