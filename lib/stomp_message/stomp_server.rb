# basic format for stomp messages
require 'rexml/document'
require 'socket'
#require 'monitor'
require 'thread'
# basic server class for listening to topics
module StompMessage
  class JmsMessage
      attr_accessor :headers, :body, :command
     def initialize(body, headers)
       self.body=body
       self.headers=headers
    end
    end
    class MySpecialListener
             include javax.jms.MessageListener if RUBY_PLATFORM =~ /java/
           def initialize(obj)
             @call_obj=obj
           end
           def set_self(obj)
             @call_obj=obj
           end
           def onMessage(msg)
             #puts "----> consumer in on msg #{msg.inspect}"
             puts "message received #{@my_topic}"
             h= {}
             msg.get_property_names.each { |n| h[n]=msg.getStringProperty(n) }
            # puts "text: #{msg.getText()} props: #{h.inspect}"
            # exit!
             @call_obj.onMessage(msg.getText(),h)
             msg=nil
             h=nil
            # puts "<--- consumer on message"
           end
     end
  
	class StompServer
	  include StompMessage::JmsTools
	#  include MonitorMixin
	  attr_accessor :conn,   :topic, :msg_count, :exception_count, :host, :port, :login, :password, :queue, :thread_count, :mythreads, :guard, :jms_source, :variables, :ss_start_time
     #need to define topic, host properly
      @debug=false
    
    def initialize(options={})
         self.mythreads = []
         self.ss_start_time=Time.now
         puts "VERSION StompServer starting:: #{self.class} #{self.version_number}"
         if RUBY_PLATFORM =~ /java/
            @javaflag= @java_flag=true
         else
           @javaflag= @java_flag=false
         end
        @my_hostname = Socket.gethostname
        self.guard    = Mutex.new  
        self.variables = []
        #  use like  self.guard.synchronize {   code for synchronize here  }
          self.login =   options[:login]==nil ? '' : options[:login]
            self.jms_source =   options[:jms_source]==nil ? nil : options[:jms_source]
          num =   options[:thread_count]==nil ? '1' : options[:thread_count]
          self.thread_count=num.to_i
            self.password =   options[:password]==nil ? '' : options[:password]
        self.host =   options[:host]==nil ? 'localhost' : options[:host]
        self.port =   options[:port]==nil ? '61613' : options[:port]
        self.topic =   options[:topic]==nil ? '/topic/please_define' : options[:topic]
        
        self.msg_count = self.exception_count=0
      
        
        if !self.java?
           self.queue= Queue.new
           self.conn=nil
          
           connect_connection
       #  self.conn = Stomp::Client.new self.login, self.password, self.host, self.port, false 
      # self.conn = Stomp::Connection.open self.login, self.password, self.host , self.port, false 
           connect_topic
           setup_auto_close
        else 
          do_jms_setup
        end
       @debug=false
       puts "#{self.class}: message broker host is: #{host} port is #{port} topic is: #{self.topic} threads #{self.thread_count} my host: #{@my_hostname} jms source #{self.jms_source} java flag #{@javaflag}"
       puts "VERSION StompServer finalized:: #{self.class} #{self.version_number}"
       
        trap("INT")   {  puts "#{Time.now}: #{self.class} in interrupt trap\n"
                          #close_topic
                          #disconnect_stomp
                          #setup_auto_close   already done in INIT
                          jms_close_connections
                          exit! }
    
       
     end
     def java?
        @javaflag
      end
     def version_number
        module_name=self.class.to_s.split('::')[0] 
        version_num = eval("#{module_name}::VERSION::STRING")  #note needs version/string
     end
     def create_dest_conn
       #  puts "IN CREATE DEST CONN"
         @ss_jms_dest, @ss_jms_conn = jms_create_destination_connection(self.topic)  if @ss_jms_conn==nil
       #  @ss_jms_conn.start if  @ss_jms_conn!=nil
       #  puts " STARTED CONNECTION"
      #   puts "JMS create dest_conn :dest #{@ss_jms_dest.inspect} conn: #{@ss_jms_conn.inspect}"
     end
     def create_jms_mdb_connections
        puts "----> entering jms mdb connections"
        jms_start("TopicConnectionFactory",self.jms_source) #if @JmsTools_conn_factory==nil
        create_dest_conn
        puts "<---- leaving jms mdb connections" # if @debug
     end
     def do_jms_setup
         puts "----> entering jms setup" #if @debug
         setup_thread_specific_items("#{self.jms_source} thread")
         create_jms_mdb_connections
     #    jms_auto_close
         check_thread
          puts "<---- leaving jms setup" # if @debug
     end
      def reconnect
          puts "about to reconnect"
          self.conn.close if self.conn!=nil
          connect_connection
         #  self.conn = Stomp::Client.new self.login, self.password, self.host, self.port, false 
        # self.conn = Stomp::Connection.open self.login, self.password, self.host , self.port, false 
         connect_topic
      end
     def connect_connection
       self.conn = StompMessage::StompSendTopic.open_connection(self.conn, self.login, self.password, self.host, self.port) 
     end
     def setup_auto_close
       at_exit { puts "#{self.class}: in at exit block"
                 close_topic
                 disconnect_stomp 
                # self.mythreads.each {|t| t.raise "auto exit" }
               }
     end
     def server_shutdown
       puts "----in server shutdown"
     end
       def jms_close_connections
          puts "----in jms close connections #{self.topic}--HERE BE DRAGONS"
         # puts "----#{@ss_jms_dest.inspect} #{@ss_jms_conn.inspect} #{@ss_session.inspect} #{@ss_producer.inspect}" 
           @ss_session.close if @ss_session!=nil
           @ss_producer.close  if @ss_producer!=nil
           @ss_jms_conn.close  if @ss_jms_conn!=nil
             @ss_consumer.close  if @ss_consumer!=nil
      #     @ss_session=@ss_producer=@ss_jms_conn=nil
           server_shutdown
           object_duration = Time.now - self.ss_start_time
           puts "---- Duration: #{object_duration} #{self.class} #{self.version_number} on topic #{self.topic}"
            #   puts "----closed session and producer #{@ss_jms_dest.inspect} #{@ss_jms_conn.inspect} #{@ss_session.inspect} #{@ss_producer.inspect}"
            object_duration=nil
            puts "----after jms shutdown #{self.topic}--- exiting"
            #exit!
       end
       def check_session  #NOT USED
        
         @ss_producer,  @ss_session = jms_create_producer_session(@ss_jms_dest, @ss_jms_conn) if @ss_producer==nil || @ss_session==nil
       end
       def jms_auto_close
          at_exit { puts "#{self.class}: in at exit block"
          # PERHAPS SET GLOBALBS for dest/conn
                   jms_close_connections
                   # self.mythreads.each {|t| t.raise "auto exit" }
                  }
        end
       def disconnect_stomp
             puts "#{self.class} #{@my_hostname} closing connection"
             self.conn.close() if self.conn !=nil   
       end
       
       
def jms_message_handling(tjms_dest, tjms_conn)
    #puts "JMS MESSAGE HNDLE #{tjms_dest.inspect} #{tjms_conn.inspect}"
        @ss_producer, @ss_session  = self.jms_create_producer_session(tjms_dest, tjms_conn)
   #     puts "JMS MESSAGE HNDLE sprod #{@ss_producer.inspect} sess #{@ss_session.inspect}"
        result = yield
        jms_close_producer_session(  @ss_producer, @ss_session )
        result
end 
     def send_reply(headers,msg)
          # if headers['reply-to']!=nil ||  headers['JMSReplyTo']!=nil
                 reply_topic=headers['reply-to']
                # create_dest_conn
                 response_header = {'persistent'=>'false'}
                 response_header.merge headers
                 response_header['id']= headers['id']
                 response_header['JMSReplyTo']= headers['JMSReplyTo']
             #    puts "SEND REPLY setting response to #{response_header['JMSReplyTo']} for id #{response_header['id']}  "
              puts "SEND REPLY #{response_header.inspect}" if @debug
                 puts "<----- reply to follow:"
                 if  self.java?
                     jms_message_handling(@ss_jms_dest, @ss_jms_conn) {                 jms_send_message(@ss_session,@ss_producer,headers,msg.to_xml)  }
                 
                 else
                   self.conn.send(reply_topic, msg.to_xml, response_header ) 
                  end
                
         #   end
     
     end
     # name is message command
     def connect_topic
       # scott old ack auot
       # see http://activemq.apache.org/stomp.html for activemq.dispathAsync settig
         self.conn.subscribe( self.topic, { :ack =>"client" , 'activemq.dispatchAsync' => 'false'}) { |msg|  
            
            self.msg_count+=1
    	       begin	
    	        self.conn.acknowledge(msg,msg.headers)   
    	        self.queue << msg  
    	         
             rescue Exception => e
               self.exception_count+=1
             puts " Thread: :exception found #{e.backtrace}" 
             puts "Thread: :exception messag #{e.message}"
            end
          
           }
     end
     # close the topic, override if necessary
     def close_topic
         puts "#{self.class} #{@my_hostname} unsubscribing #{self.topic}"
          self.conn.unsubscribe self.topic  if self.conn!=nil
      end
      def stomp_PING(msg,stomp_msg)
        body="ALIVE Class: #{self.class.to_s} id: #{self.object_id} listening to: #{self.topic} on host #{@my_hostname} id  thread #{Thread.current.inspect}  msg_count #{self.msg_count} exception_count #{self.exception_count} time: #{Time.now}\n"
          body << "Object details  #{self.inspect}"  if @debug
         reply_msg = StompMessage::Message.new('stomp_REPLY', body)
          [true, reply_msg]
     
      end
      def check_thread
         if @debug  
            puts "----check thread id: #{get_id} Thread value: #{Thread.current.inspect}  "
            self.variables[get_id].each { |key, val| 
                puts "---- key #{key} is: #{val.inspect}"}
         end
      end
      def stomp_RECONNECT(msg,stomp_msg)
        reconnect
      
        body="ALIVE Class: #{self.class.to_s} listing to: #{self.topic} on host #{@my_hostname} msg_count #{self.msg_count} exception_count #{self.exception_count} id #{self.inspect} thread #{Thread.current.inspect} connection status #{self.conn.open?}"
         reply_msg = StompMessage::Message.new('stomp_REPLY', body)
         [true, reply_msg]
        
      end
     def stomp_DEBUG(msg,stomp_msg)
       
        @debug=!@debug
        puts "debug flag is now #{@debug}"
         [false, ""]
     end
     def method_missing(name, *args)
       puts "Method missing called: #{name}"
       puts "Likely invalid message recieved"
          [false, ""]
     end
     # monitor queue
     def monitor_queue_status
       puts "starting up queue status"
       self.mythreads << Thread.new { while true
                    begin
                      sleep(1000)
                      puts "QUEUE size is: #{self.queue.size}"
                     # puts "-------conn var is on #{self.conn.inspect}"
                       if !self.conn.open? 
                         puts "restarting connection"
                         self.reconnect
                       end
                     rescue Exception => e
                       handle_exception(e)
                     end
                    end  # while
                     }
     end
     def handle_exception(e)
       puts " Thread: #{Thread.current[:name]} :exception found #{e.backtrace}" 
       puts "Thread: #{Thread.current[:name]} :exception messag #{e.message}"
       result = "-----------EXCEPTION FOUND----------\n"
       result << "ALIVE Class: #{self.class.to_s} listing to: #{self.topic} on host #{@my_hostname} msg_count #{self.msg_count} exception_count #{self.exception_count}\n"
       result << "-----exception data--------\n"
       result << " Thread: #{Thread.current[:name]} :exception found #{e.backtrace}\n" 
       result << "Thread: #{Thread.current[:name]} :exception messag #{e.message} e: #{e.inspect}"
         begin
           StompMessage::StompSendTopic.send_email_stomp("scott.sproule@cure.com.ph",
                   "STOMP EXCEPTION", "scott.sproule@cure.com.ph","Thread: #{Thread.current[:name]} :exception messag #{e.message}", result)
         rescue Exception => e
            puts "Can not send email, please check smtp host setting"
         end
     end
     def check_origin(thash)
       flag= false
        src_id = thash['JMSOrigin']
        flag= src_id.to_s!=self.jms_source if src_id!=nil
        #puts "ORIGIN FLAG #{flag}"
        flag
     end
       def onMessage(msg_body,msg_hash)
           puts "message body is : #{msg_body} hash #{msg_hash}"      if @debug
           puts "my id is #{jms_my_id} message id is #{msg_hash['JMSOrigin']}"   if @debug
            start_time=Time.now
           if check_origin(msg_hash)
           begin
              self.msg_count+=1
              check_thread    if @debug
   	          m=StompMessage::Message.load_xml(msg_body)
   	          puts "----> #{Time.now} received msg is #{m.command}" # if @debug
      	       msg=StompMessage::JmsMessage.new(msg_body,msg_hash)
      	       puts "jms message: #{msg.inspect}" if @debug
      	     
      	       r=send(m.command, m, msg)
      	        duration=Time.now-start_time
      	        puts "--- Message processing before reply: #{self.topic}: #{m.command} : #{duration}"
      	       send_reply(msg.headers,r[1])    if r[0]==true
  	           duration=Time.now-start_time
  	         
  	           puts "--- Message processed #{self.topic}: #{m.command} : #{duration}"
  	             m=nil
   	        rescue Exception => e
   	           self.exception_count+=1
               handle_exception(e)
 	          end
 	         else
 	           puts "----> received message from myself...ignoring #{msg_hash['JMSOrigin']}"
 	         end   #JMS Origin if
 	         msg_body=msg_hash=nil
 	         puts "<-----finished onMesage"
   	      # puts "Message is: #{m.to_xml}"  if @debug
   	        # effectively case statement  (Should SCREEN HERE)
   	      # puts "sms text is: #{sms.text} dest is: #{sms.destination} result is: #{res}"
        end
     def handle_message(msg)
        puts "STOMP message frame is : #{msg} "      if @debug
	       m=StompMessage::Message.load_xml(msg.body)
	      # puts "Message is: #{m.to_xml}"  if @debug
	       puts "Message type is #{m.command}" if @debug
	       r=send(m.command, m, msg)
 	       send_reply(msg.headers,r[1]) if r[0]=true
	      # puts "sms text is: #{sms.text} dest is: #{sms.destination} result is: #{res}"
     end
     #define thread specific variables here
     # eg Thread.currect[:smsc]=blah blah
     def get_id
         id = Thread.current[:id] 
         id = 1 if @java_flag
         id
     end
     def setup_thread_specific_items(mythread_number)
        puts "----> entering setup threads #{mythread_number}" # if @debug
       Thread.current[:name]= "Thread: #{mythread_number}"
       Thread.current[:id]=mythread_number
       self.variables[get_id]={}
       
       #self.variables[get_id][:test_field]='test problem'
       check_thread
       puts "<---- leaving setup threads" if @debug
       
     end
     def run
          1.upto(self.thread_count)   { |c|  # create the threads here
            #puts "creating thread: #{c}"
            self.mythreads << Thread.new(c)   { |ctmp| 
               setup_thread_specific_items(ctmp)
               while true
                
                  begin	
          	        msg=self.queue.pop
                    handle_message(msg)   
                   
                   rescue Exception => e
                     self.exception_count+=1
                     handle_exception(e)
                  end
             #   Thread.pass
               end
              }
            }
           monitor_queue_status
           self.mythreads.each { |t| t.join }
          
          
   	     #  msg = self.conn.receive
   	#       puts "after receive"
   	     #  self.msg_count+=1
   	     #  begin	
   	    #     handle_message(msg)      
         #   rescue Exception => e
        #      self.exception_count+=1
         #   puts "exception found #{e.backtrace}" 
        #    puts "exception messag #{e.message}"
         #  end
         # end  # while

       # t.join  # wait for t to die..
     end #run
  end
end