require 'yaml'
require 'rubygems'
gem 'stomp'
require 'stomp'
require 'net/smtp'
require 'net/http'
require 'socket'
if RUBY_PLATFORM =~ /java/
require 'java'
end


# This 
module StompMessage
  # this class manages sending and receiving messages.  It uses passed code block to execute received code
class StompSendTopic
  attr_accessor :conn, :topic, :host, :port, :login, :password, :url
  #need to define topic, host properly
  include StompMessage::JmsTools if RUBY_PLATFORM =~ /java/
 def initialize(options={})
   # set up variables using hash
    @close_ok=false
     init_vars(options)
         if RUBY_PLATFORM =~ /java/
             @javaflag= @java_flag=true
          else
            @javaflag= @java_flag=false
          end
      set_up_jms(options[:topic]) if @javaflag
  #  puts "host is: #{host} port is #{port}"
  # using url as flag wrong
  #  self.conn = Stomp::Client.new(self.login, self.password, self.host, self.port, false) if self.url ==nil
    @debug=false
    
    puts "#{self.class}: Initialized host is: #{self.host} port is #{self.port} topic is #{self.topic} login #{self.login} pass: #{self.password}" if @debug
    # scott old   self.conn.subscribe( self.topic, { :ack =>"auto" })  { |m| 
 #    self.conn.subscribe( self.topic, { :ack =>"client" })  { |m| 
  #                                 # puts "#{self.class} msg: #{m.to_s}"
  #                                   }
   # setup_auto_close
  end
  def jms_msg_result(msg)
      #tproducer, tsession= self.jms_create_producer_session(@jms_dest,@jms_conn)
       @my_conn=@jms_conn
     #  tconsumer=jms_create_consumer(tsession,@jms_dest)
   #   tconsumer, consumer_session = self.jms_create_consumer_session(@jms_dest,@jms_conn) 
      #  result =jms_send_ack(tsession,tproducer,msg.to_xml)
       # tsession.commit
       # tconsumer.close
      #  self.jms_close_producer_session(tproducer, tsession)
           result =jms_message_handling(@jms_dest, @jms_conn)  {     jms_send_ack(@session,@producer,msg.to_xml,50) }
       # self.close_con
       msg=nil
     result
  end
  def set_up_jms(topic)
      jms_start("TopicConnectionFactory")   #THIS NEEDS TO BE A VAR
      @jms_dest, @jms_conn = jms_create_destination_connection(topic)
      # @session = jms_create_session( topic)
     # @producer = jms_create_producer(@session,@dest)
     #  @consumer = jms_create_consumer(@session,@dest)
     # at_exit { puts "#{self.class}: auto close exit block"  #if @debug
     #         send_topic_jms_shutdown }
   end
   def send_topic_jms_shutdown
     jms_shutdown(@jms_dest, @jms_conn, @session, @producer, @consumer)
   end
   
  def init_vars(options)
     self.login =   options[:login]==nil ? '' : options[:login]
      self.url =   options[:url]== nil ? nil : options[:url]
        self.password =   options[:password]==nil ? '' : options[:password]
          self.host =   options[:host]==nil ? 'localhost' : options[:host]
      self.port =   options[:port]==nil ? '61613' : options[:port]
      self.topic = options[:topic]==nil ? '/topic/undefined' : options[:topic]  
      self.conn=nil
      puts "self url is #{self.url}" if @debug
  end
  def java?
    @javaflag
  end
  # only call this once
  def setup_auto_close
    
     at_exit { puts "#{self.class}: auto close exit block"  if @debug
           if !self.java?
               close_topic
              disconnect_stomp 
            end } if !@close_ok
      @close_ok=true
  end  
  #manage timeout etc...
  def self.open_connection(old_conn,login,pass,host,port)
      conn=old_conn
      count=0
      flag= false
     begin
      conn.close if conn!=nil
      count+=1
      Timeout::timeout(15) {
           conn=nil
           conn = Stomp::Client.new(login, pass, host, port, false)
           flag=true
       }
   
       rescue Timeout::Error
        puts "Timeout error: exception retrying flag is: #{flag} retry number #{count}"
        retry  if !flag and count < 4
     #   raise "timeout" 
    
       end 
        raise 'connection not established'  if conn==nil        
        conn
  end
  def open_connection
    self.conn = StompMessage::StompSendTopic.open_connection(@conn, self.login, self.password, self.host, self.port) if self.conn==nil
  end
  # close the topic
   def close_topic
        self.conn.unsubscribe(self.topic) if self.conn !=nil && !self.java?
      #  self.conn=nil 
    end
    #disconnect the connection
    def disconnect_stomp
        if !self.java?
           close_topic
           puts "#{self.class}  closing connection #{@jms_conn.inspect}" if @debug
          @jms_conn.close() if @jms_conn !=nil   
        else
          @jms_conn.close() if @jms_conn !=nil   
          put "INVESTIGATE THIS diconnect stomp if java in stomp_send_topic.rb"
        end
    end
    # post stomp message to url
    def post_stomp(msg,headers)
           
           response_header = {"Content-type" => "text/xml"}
           response_header.merge headers
           ht =Net::HTTP.start(self.host,self.port)
           url = self.url # + "/" + self.topic
            puts "posting to: #{self.host}: #{self.port} #{url} message: #{msg.to_xml}"
           r=ht.post(url,msg.to_xml,response_header)
          
           puts "result: #{r.to_s}"
           r
    end
    def jms_message_one_way(tjms_dest,tjms_conn)
        # @my_conn=@jms_conn
           @producer, @session  = self.jms_create_producer_session(tjms_dest,tjms_conn)
      #   tconsumer=jms_create_consumer(@session,@jms_dest)
         #@producer, @session  = self.jms_create_producer_session(tjms_dest,tjms_conn)
         ttresult = yield
       #  tconsumer.close
         jms_close_producer_session(  @producer, @session )
         ttresult
      end
     def jms_message_handling(tjms_dest,tjms_conn)
          @my_conn=@jms_conn
            @producer, @session  = self.jms_create_producer_session(tjms_dest,tjms_conn)
          tconsumer=jms_create_consumer(@session,@jms_dest)
          #@producer, @session  = self.jms_create_producer_session(tjms_dest,tjms_conn)
          result = yield
          tconsumer.close
          jms_close_producer_session(  @producer, @session )
          result
       end
  def send_topic(msg, headers, &r_block)
        #  m=StompMessage::Message.new('stomp_BILLING', msg)
           open_connection
           more_headers= {'persistent'=>'false' }
           # i think bug in this merge..needs to return result
           more_headers.merge headers
           if self.java?
             jms_message_handling(@jms_dest, @jms_conn) {  self.jms_send_message(@session,@producer,headers,msg.to_xml)  }
           else
             self.conn.send(self.topic, msg.to_xml, more_headers, &r_block)
           end
        #  Thread.pass
   end #send_sms
   def interim_package(msg,headers,timeout)
     result=false
     msg_received_flag =false
     begin
     Timeout::timeout(timeout+1) {
       self.send_topic_acknowledge(msg,headers,timeout-1)  {   |msg| # puts 'in handle action block' 
                           #  puts "MESSAGE RECEIVED ---- #{msg.to_s} "
                             msg_received_flag=true
                             m=StompMessage::Message.load_xml(msg)
                             result=m.body
                          #    result= yield m.body if block_given? FIGURE OUT HOW TO MAKE THIS WORK
                           #  puts "result is #{result}"
                             result
                              }
                   
                              while true  
                             #    putc '.'
                                 break if msg_received_flag
                                 sleep(1)
                                 end  }
                           rescue SystemExit
                           rescue Timeout::Error
                           rescue Exception => e
                            puts "exception #{e.message} class: #{e.class}"
                            puts  "no receipt"
                           end
                result
   end
   def create_consumer
      @consumer, @consumer_session = jms_create_consumer_session(@jms_dest,@jms_conn) 
   end
   def send_topic_ack(msg,headers,timeout=75, &r_block)
      
      result=false
      #puts "Send topic ack"
      
      if self.java?
        #create_consumer if @consumer==nil
        result =jms_message_handling(@jms_dest, @jms_conn)  {     jms_send_ack(@session,@producer,msg.to_xml,timeout) }
      else
          result =interim_package(msg,headers,timeout)
       end
            result
         # puts "result is now #{result}"
   end
   # be careful with the receipt topic calculations... strange errors onactive mq
 def send_topic_acknowledge(msg, headers, timeout=60)
          #m=StompMessage::Message.new('stomp_BILLING', msg)
          open_connection
          s=rand*30   # scott - used to be 1000 but seem to create connections on activemq
          # open new topic to listen to reply...
           # was this but jms seems to blow up  receipt_topic="/topic/receipt/client#{s.to_i}"
          receipt_topic="/topic/rcpt_client#{s.to_i}"
          receipt_flag = false
         # internal_conn =  Stomp::Connection.open '', '', self.host, self.port, false 
          self.conn.subscribe( receipt_topic, { :ack =>"client" })   {|msg|
                        begin
                        Timeout::timeout(timeout) {
                            self.conn.acknowledge(msg,msg.headers)
                    	      msg2= msg.body
                    	       yield msg2
                         }
                         rescue Exception => e
                          puts "exception #{e.message}"
                       #   raise "timeout" 
                         ensure
                           receipt_flag=true
                           self.conn.unsubscribe receipt_topic 
                         end   
                           }
                          
          
          more_headers= {'persistent'=>'false',  'reply-to' => "#{receipt_topic}" }
          more_headers.merge headers
          self.conn.send(self.topic, msg.to_xml, more_headers )  
          Thread.new {   sleep(timeout+1)
                          puts "calling unsubscribe on #{receipt_topic}" if !receipt_flag
                          self.conn.unsubscribe receipt_topic if !receipt_flag
                           }       
      end #send_sms
      def send_email_stomp(from, from_alias, to, subject, message)
        StompMessage::StompSendTopic.send_email_stomp(from,from_alias,to,subject,message)
      end
      def self.send_email_stomp(from, from_alias, to, subject, message)
          #to_csv_array=to.each.join(",")
        	msg = <<EOF__RUBY_END_OF_MESSAGE
From: #{from_alias} <#{from}>
To: #{to}
Subject: #{subject} #{Time.now}
Comand ----------
#{subject}
RESPONSE -----------
#{message}
EOF__RUBY_END_OF_MESSAGE
         recipients=to.split(',')
         recipients.each {|r|  StompMessage::StompSendTopic.send_email(from,r,msg)}
        
    end
    def  self.send_email(from,to,msg)
          case   Socket.gethostname
          when "svbalance.cure.com.ph"
                smtp_host='mail2.cure.com.ph'
          when "Scotts-Computer.local"
            smtp_host='mail2.cure.com.ph'
          else
            smtp_host='localhost'
          end
          
        	Net::SMTP.start(smtp_host) { |smtp|
        		smtp.send_message(msg, from, to)
      	   }
    end
        
 end # stomp send topic

end #module
