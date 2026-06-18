# does the actual request sending using the crystal http/client stdlib 
require "http/client"
module HTTPX::Internal
  class Client
    @http : HTTP::Client?
    @host : String
    @port : Int32
    @tls : Bool

    def initiaize(@host : String, @port : Int32 = 80, @tls : Bool = false)
      @http = HTTP::Client.new(@host, @port, tls: @tls)
      @http.read_timeout = 5.seconds
      @http.connect_timeout = 5.seconds
    end

    def execute(request : HTTP::Request) : HTTP::Client::Response
      @http.exec(request)
      rescue ex : IO::TimeoutError
       raise HTTPX::TimeoutError.new("Request Timed Out")
      rescue ex : OpenSSL::SSL::Error
       raise HTTPX::SSLError.new("SSL handshake failed #{ex.message}")
    end

    def close : Nil
      @http.close
    end

    def is_connected? : Bool
      !@http.closed?
    end

    def host : String
      @host
    end
  end
end
       
      
