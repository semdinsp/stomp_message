#!/usr/bin/env jruby -S
# == Synopsis
#   Listen to topic and print it out.... ctrl -c to end
# == Usage
#  jms_message_send.rb -T topic 
# == Useful commands
#  jruby -S jms_topic_listener.rb  -T sms
# == Author
#   Scott Sproule  --- Ficonab.com (scott.sproule@ficonab.com)
# == Copyright
#    Copyright (c) 2007 Ficonab Pte. Ltd.
#     See license for license details
require 'yaml'
require 'rubygems'
gem 'stomp'
require 'stomp'
require 'optparse'
gem 'stomp_message'
require 'stomp_message'
require 'rdoc/usage'
require 'java'
include StompMessage::JmsTools
#Hashtable=java.util.Hashtable
#Context=javax.naming.Context
#InitialContext = javax.naming.InitialContext
#Session = javax.jms.Session


 arg_hash=StompMessage::Options.parse_options(ARGV)
 RDoc::usage if  arg_hash[:topic]==nil || arg_hash[:help]==true
require 'pp'
  options = arg_hash
@my_topic = arg_hash[:topic]
   # set up variables using hash
class MySpecialListener
         include javax.jms.MessageListener if RUBY_PLATFORM =~ /java/
       def set_self(meth)
         @to_call=meth
       end
       def onMessage(msg)
         #puts "----> consumer in on msg #{msg.inspect}"
         puts "message received #{@my_topic} msg: #{msg.inspect}"
        # puts "<--- consumer on message"
       end
 end   
   jms_start("TopicConnectionFactory")
   jms_set_debug(arg_hash[:debug])
   tdest, tconn= jms_create_destination_connection( arg_hash[:topic])
   tproducer, tsession= jms_create_producer_session(tdest,tconn)
   tconsumer, consumer_session = jms_create_consumer_session(tdest,tconn) 
    tlistener=MySpecialListener.new
    tconsumer.setMessageListener(tlistener)
  puts "listener set"
    while true  
      sleep(0.25)
     end
  #   consumer_session.close
     #puts "#{result}"
 #  sleep(1)
   
  
    
    puts  '-------------finished processing!!!'
   # sleep(15)
   # puts "producer id #{producer.getProducerID}"
    jms_shutdown(tdest, tconn, tsession, tproducer, tconsumer )
   
  
    
   # Thread.exit
    exit!
  
