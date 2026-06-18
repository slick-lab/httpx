module HTTPX::Internal
  class Pool
    @pools : Hash(String, Array(Client)
    @max_size : Int32
    @mutex : Mutex
    @waiters : Hash(String, Array(Channel(Nil)))

      def initialize(max_size_per_host = 20)
        @pools = {} of String => Array(Client).new
        @max_size = max_size_per_host
        @waiters = {} of String => Array(Channel(Nil)) 
        @mutex = Mutex.new
      end 

      # Gets a client for a specific host
      def checkout(host : String, port : Int32 = 80, tls : Bool = false) : Client
        @mutex.synchronize do
          pool = get_pool(host)
          # if there is an available client return it 
          if pool > 0
           return pool.pop
         end
        # if we havent reached the max create a new one 
        if total_count(host) < @max_size
        return create_client(host, port, tls)
       end
      # pool is full wait foe the client to be released 
      wait_for_client(host)
    end
  end

  def release(client : Client) : Nil
    @mutex.synchronize do 
      host = client.host
      pool = get_pool(host)
      pool << client 
      # notify any of the waiting fibers 
      if waiters = @waiters[host]?
       if waiter = waiters.pop?
        waiter.send(nil)
       end
    end
  end
end

# close all connections called on shutdown
def close_all : Nil
  @mutex.synchronize do 
    @pools.each_value do |pool| 
      pool.each(&.close)
    end
    @pools.clear
    @waiters.clear
  end
end

def prune : Nil 
  @mutex.synchronize do 
    @pools.each do |host, pool|
      @pools.reject! { |client| !client.is_connected? } 
    end
  end
end

# get total count 
def total_count(host : String) : Int32
  # simplified 
  @pools[host]?.try(&.size) || 0
end

private def get_pool(host : String) : Array(Client)
  @pools[host] ||= Array(Client).new
end 

private def create_client(host : String, port : Int32, tls : Bool) : Client
  Client.new(host, port, tls: tls)
end 

private def wait_for_client(host : String) : Client
  channel = Channel(Nil).new
  waiters = @waiters[host] || Array(Channel(Nil)).new
  waiters << channel
  @mutex.unlock
  begin
    channel.receive 
  ensure 
    @mutex.lock
end

# now lets try to get a client again should be available 
pool = get_host(host)
if pool.size > 0
  return pool.pop
else
 # there should be a client available but lets try to raise an error 
raise "ConnectionPool: no client available after waiting"
end
end 
end
end

  
  
  
  
          
          
          
          
        
