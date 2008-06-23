if RUBY_PLATFORM =~ /java/
require 'java'
#module Java
#include_class 'java.lang.String'
#end
import java.util.Hashtable
import javax.naming.Context
import javax.naming.InitialContext
import javax.jms.Message
import javax.jms.MessageListener
import javax.jms.Session
import javax.jms.ConnectionFactory
import javax.jms.TopicConnectionFactory
#import javax.jms.MessageListener
end


module StompMessage
  module JmsTools
    
class MyListener
      include javax.jms.MessageListener if RUBY_PLATFORM =~ /java/
    def set_self(meth)
      @to_call=meth
    end
    def onMessage(msg)
      #puts "----> consumer in on msg #{msg.inspect}"
      @to_call.send('jms_on_message',msg)
     # puts "<--- consumer on message"
    end
end
    def jms_next_transaction_id
       puts "--- before trans id #{@transaction_id}"  if  @JmsTools_debug
       @my_jms_guard_tx.synchronize {
             @transaction_id+=1 }
       puts "--- after increment trans id #{@transaction_id}"  if  @JmsTools_debug
       @transaction_id
    end
    def define_source_id
      # maybe should user producer id
       @source_id=rand*10000 + rand*400+1 #if @source_id==0
       @source_id=@source_id.to_i.to_s
       puts "--- source id #{@source_id}"  if  @JmsTools_debug
    end
    def unique_source_id      
         @source_id
    end
    def jms_my_id      
           @source_id
    end
    
     def jms_set_debug(val)    
             val=false if val==nil
             @JmsTools_debug = val
      end
    def jms_start(factory,src_id=nil)
      jms_set_debug(false)
      @my_jms_guard    = Mutex.new  
      @my_jms_guard2    = Mutex.new  
        @my_jms_guard3    = Mutex.new 
          @my_jms_guard_tx    = Mutex.new  
     # @source_id=0   # DEFINE SOURCE ID IF MULTIPLE INSTANCES
      @source_id=src_id
      define_source_id if src_id==nil
       puts "-----> JMSTools start #{Time.now}" #if  @JmsTools_debug
      jms_kill_logging if  !@JmsTools_debug
     
      @JmsTools_current_id=0
      properties=Hashtable.new(2)
      #properties.put(Context::PROVIDER_URL, "iiop://127.0.0.1:3700")
      #properties.put(Context::INITIAL_CONTEXT_FACTORY, "com.sun.appserv.naming.S1ASCtxFactory")
      properties.put(Context::PROVIDER_URL, "file:///opt/local/imqobjects")
        properties.put(Context::INITIAL_CONTEXT_FACTORY, "com.sun.jndi.fscontext.RefFSContextFactory")
      
      @JmsTools_ctx=InitialContext.new(properties)
      puts "after initial context #{@JmsTools_ctx.inspect}" if  @JmsTools_debug
      @JmsTools_conn_factory=@JmsTools_ctx.lookup(factory) 
      puts "PROBLEM jms_start context:  #{@JmsTools_ctx.inspect} factory: #{@JmsTools_conn_factory} "  if @JmsTools_ctx==nil || @JmsTools_conn_factory==nil
     
      temp_tx_id=   rand*400+1 # set up random start id
       @transaction_id=temp_tx_id.to_i
      @response_block_list = {}
      puts "<------ ending start #{Time.now}" if  @JmsTools_debug
      
    end
    def jms_manage_headers(headers)
             headers.each do |k, value|
               key=k.to_s
               if ['correlation-id', 'JMSCorrelationID'].include? key
                    headers['JMSCorrelationID']= value.to_s
                  elsif ['expires', 'JMSExpiration'].include? key
                    headers['JMSExpiration']= value.to_i
                  elsif ['persistent', 'JMSDeliveryMode'].include? key
                    headers['JMSDeliveryMode'] = value ? 2 : 1
                  elsif ['priority', 'JMSPriority'].include? key
                     headers['JMSPriority']= value.to_i
                 # elsif ['reply-to', 'JMSReplyTo'].include? key
                  #   headers['JMSReplyTo']= nil
                  elsif ['type', 'JMSType'].include? key
                     headers['JMSType']= value.to_s
                  else #is this the most appropriate thing to do here?
                    headers[key] = value.to_s
                  end
              end
              # need to turn off persistence, and reply to fix
            # if headers['JMSReplyTo']==nil
                # headers['JMSReplyTo']= @source_id
                # CHECK headers['reply-to']= @source_id
            # end
              headers['JMSOrigin']=unique_source_id.to_s
              puts " --- headers reply #{ headers['JMSReplyTo']} source #{@source_id} id #{headers['JMSMessageID']}"  if  @JmsTools_debug
              puts "--- headers #{headers.to_s}" if  @JmsTools_debug
              headers
      
    end
    def jms_kill_logging
      puts "in disabling logging" if  @JmsTools_debug
      enm=java.util.logging.LogManager.log_manager.logger_names
      while enm.hasMoreElements do
        t_logger= java.util.logging.Logger.getLogger(enm.nextElement)
        puts "logger is: #{t_logger.inspect}" if  @JmsTools_debug
        t_logger.level = java.util.logging.Level::OFF if ENV==nil
      end
      enm=nil  # free for GC
    end
    def jms_persistent
      1  #2 is persistent
    end
    # use the raw flag to get the whole message back
    def jms_send_ack(session,producer,tmp_text,ttimeout=75, rawflag=false)
       # scott new comment  msg=session.create_text_message
        jms_temp_result =''
      @my_jms_guard.synchronize {
       #  jms_next_transaction_id
         jms_tmp_header={}
         jms_temp_result=''
         begin 
         count =0;
         Timeout::timeout(ttimeout) {
               tmp_msg_recv_flag=false
               jms_send_message(session,producer,jms_tmp_header,tmp_text)  { |t2msg|
                          #puts "message recieved: #{t2msg.inspect}" 
                          temp_m=StompMessage::Message.load_xml(t2msg.get_text())
                          jms_temp_result = temp_m.body 
                          jms_temp_result = temp_m if rawflag
                           tmp_msg_recv_flag=true
                           }
                        #  sleep(0.05)
                           while true  
                           #    putc '.'
                               count +=1
                               break if tmp_msg_recv_flag
                               sleeptime=count*0.01
                               count= 5 if count > 100  #don't let count get too big
                               sleep(sleeptime) 
                              # puts "----sleeptime is: #{sleeptime} count: #{count}" 
                               end
          }

          rescue Timeout::Error
            jms_temp_result="timeout waiting for response"
          end
         }
          return jms_temp_result
    end
    def jms_send_message(session,producer,initial_headers,txt, &block)    
    @my_jms_guard3.synchronize {
      msg=session.create_text_message
      jms_next_transaction_id
      headers={}
      # puts "initail headers #{initial_headers.inspect} reply to: #{initial_headers['JMSReplyTo']}"
      if initial_headers['JMSReplyTo']==nil
         initial_headers['id']=@transaction_id.to_s
      else 
        puts "reply message id is #{initial_headers['id']}" if  @JmsTools_debug
      end
      headers=jms_manage_headers(initial_headers)
      #msg.setIntProperty("id", next_transaction_id)
       if block_given?
          puts "----> adding #{@transaction_id} to my block list msg txt #{txt}"  if  @JmsTools_debug
          headers['JMSReplyTo']= unique_source_id
          @response_block_list[@transaction_id.to_s]=block
        end
      headers['JMSOrigin']= unique_source_id.to_s
      headers.each do |k,v|
        #key=Java::java.lang.String.new(k.to_s)
        msg.setStringProperty(k.to_s,v.to_s)
      end
       msg.setJMSDeliveryMode(jms_persistent)   #2 is persistent
      msg.set_text(txt)
      producer.send(msg)
       msg=nil
      puts "---> jms_send_message sending #{txt}" if  @JmsTools_debug
      puts " ----> jms_send_message" }
      
    end
     def jms_create_producer(session,dest)
        puts "----> in create producer #{Time.now}" if  @JmsTools_debug
        producer=session.create_producer(dest)
        puts "<----- returning create producer #{Time.now}" if  @JmsTools_debug
        return  producer
    end
    def jms_message_for_me(msg)
      @my_jms_guard2.synchronize {
      if msg.getStringProperty('JMSReplyTo')==unique_source_id
          puts "message for ME...YAHOO"  if  @JmsTools_debug
          tx_id= msg.getStringProperty('id')
       # puts "id is #{tx_id} size is: #{@response_block_list.size} inspect #{@response_block_list.inspect}"
          block=@response_block_list[tx_id.to_s]
         # puts "calling block for #{tx_id}"  if block!=nil
           block.call(msg) if block!=nil
           @response_block_list.delete(tx_id.to_s) if block!=nil
           puts "NO BLOCK FOUND FOR MY MESSAGE #{tx_id}" if block==nil
       else
        puts "found message for another person---discard"  if  @JmsTools_debug
      end
    }
    end
    def jms_on_message(msg)
      puts "-----> jms on message" if  @JmsTools_debug
       if msg.getStringProperty('JMSOrigin')!=jms_my_id
         jms_message_for_me(msg)
       else
         puts "received message from myself--- discard"  if  @JmsTools_debug
       end
        puts "<----- jms on message" if  @JmsTools_debug
    end
     def jms_create_consumer(session,dest)
        puts "----> in create consumer" if  @JmsTools_debug
        consumer=session.create_consumer(dest)
        listener=MyListener.new
        listener.set_self(self)
         consumer.setMessageListener(listener)
         @my_conn.start
        puts "<----- returning create consumer" if  @JmsTools_debug
        return  consumer
    end
     def jms_create_consumer_session(tdest,cconn)
        puts "----> in create consumer session" if  @JmsTools_debug
         ctsession = cconn.create_session(false,Session::AUTO_ACKNOWLEDGE)  # CHEcK AUTo ACK
        consumer=ctsession.create_consumer(tdest)
        listener=MyListener.new
        listener.set_self(self)
         consumer.setMessageListener(listener)
         @my_conn=cconn
         @my_conn.start
        puts "<----- returning create consumer session" if  @JmsTools_debug
        return  consumer, ctsession
    end
    def jms_create_producer_session(tdest,cconn)
      puts "----> in create producer session #{Time.now}" if  @JmsTools_debug
           session = cconn.create_session(false,Session::AUTO_ACKNOWLEDGE)  # CHEcK AUTo ACK
           producer= session.create_producer(tdest)
       puts "<----- returning create session #{Time.now}" if  @JmsTools_debug
        return producer, session
    end
     def jms_close_producer_session(tprod,tsession)
           puts "----> in jms close producer session #{Time.now}" if  @JmsTools_debug
         # tsession.commit
          tprod.close if tprod!=nil
          tsession.close if tsession!=nil
           puts "<--- in jms close producer session #{Time.now}" if  @JmsTools_debug
      end
     def jms_create_destination_connection(name)
        puts "----> in create destination connection #{Time.now}" if  @JmsTools_debug
        tdest=@JmsTools_ctx.lookup(name)
        tconn=@JmsTools_conn_factory.create_connection
       # @my_conn=tconn
         puts "----- dest #{tdest.inspect} conn #{tconn.inspect}" if  @JmsTools_debug
        puts "<----- destination connection #{Time.now}" if  @JmsTools_debug
        return tdest, tconn
      end
     
    def jms_create_session(name)
      puts "----> in create session #{Time.now}" if  @JmsTools_debug
      dest=@JmsTools_ctx.lookup(name)
      conn=@JmsTools_conn_factory.create_connection
      @my_conn=conn
      # SET CONNECTION PARAMETERS TO OPTIMIZE THROUGHPUT HERE
     #  conn.setStringProperty('imqJMSDeliveryMode','1')
   #  conn.setimqJMSDeliveryMode(jms_persistent)
     session = conn.create_session(false,Session::AUTO_ACKNOWLEDGE)  # CHEcK AUTo ACK
   #   session = conn.create_session(false,Session::DUPS_OK_ACKNOWLEDGE)  # CHEcK AUTo ACK
    #  conn.start
       puts "----- dest #{dest.inspect} conn #{conn.inspect}" if  @JmsTools_debug
      puts "<----- returning create session #{Time.now}" if  @JmsTools_debug
      return dest, conn, session
    end
   
    def jms_shutdown(tdest, tconn, tsession, tproducer, tconsumer=nil)
      puts "----> in shutdown " if  @JmsTools_debug
      #dest.shutdown
     # puts "shutdown #{dest.methods.join(',').to_s}" if  @JmsTools_debug
      puts "conn: #{tconn.inspect} session #{tsession.inspect} producer #{tproducer.inspect}" if  @JmsTools_debug
      @my_conn=nil
      tproducer.close if tproducer != nil
      tconsumer.close if tconsumer != nil
    
      tsession.close if tsession!=nil
      tconn.stop if tconn!=nil
      tconn.close() if tconn!=nil
       tconn.close if tconn!=nil
       @JmsTools_ctx.close
       tdest=tconn=tsession=tproducer= @JmsTools_ctx=nil
         @response_block_list=nil
           @my_jms_guard = @my_jms_guard2 = @my_jms_guard3    =    @my_jms_guard_tx=nil
         

     # puts "---CLOSED conn: #{tconn.inspect} session #{tsession.inspect} producer #{tproducer.inspect} conn factory: #{@JmsTools_conn_factory}" if  @JmsTools_debug
      puts "<----- returning shutdown " if  @JmsTools_debug

    end
    
  end
end