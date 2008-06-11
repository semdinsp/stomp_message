#!/usr/bin/env jruby -S
# == Synopsis
#   Send a message to a jms server and wait for result if requested
# == Usage
#  jms_message_send.rb -T topic -M command -b body -h host -p port " 
#   Debug: to turn on debug: stomp_message_send.rb -T '/topic/sms' -M stomp_DEBUG -b nil
#   Statistics:  stomp_message_send.rb -T '/topic/sms' -M stomp_REPORT -b nil -A true
#    Reconnect: stomp_message_send.rb -T '/topic/sms' -M stomp_RECONNECT -b nil -A true  ---- NOT USED OFTEN
# Ping:  for ping test: stomp_message_send.rb -T '/topic/sms' -M stomp_PING -b nil -A true
# Ping: for email ping test: stomp_message_send.rb -T '/topic/sms' -M stomp_PING -b nil -A true -D comma_separated_email_addresses"
# Note -a flag for response  --- eg true or false
# == Useful commands
#  jruby -S jms_message_send.rb  -M stomp_PING -b nil -A true -T sms
#  jruby -S jms_message_send.rb  -M stomp_DEBUG -b nil -d  -T sms
# jruby -S  jms_message_send.rb -M stomp_REPORT -b nil -A true -D email@com  -T sms
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
 RDoc::usage if  arg_hash[:topic]==nil || arg_hash[:command]==nil || arg_hash[:help]==true
require 'pp'
  options = arg_hash
   # set up variables using hash
   
   jms_start("TopicConnectionFactory")
   jms_set_debug(arg_hash[:debug])
   tdest, tconn= jms_create_destination_connection( arg_hash[:topic])
   tproducer, tsession= jms_create_producer_session(tdest,tconn)
   tconsumer, consumer_session = jms_create_consumer_session(tdest,tconn) 
   msg=StompMessage::Message.new(options[:command],options[:body])
  # msg=StompMessage::Message(arg_hash[:command],'hello body there')
     count = arg_hash[:count]==nil ? 1 : arg_hash[:count].to_i
 
     result =jms_send_ack(tsession,tproducer,msg.to_xml) 
  #   consumer_session.close
     puts "#{result}"
 #  sleep(1)
   
  
    
    puts  '-------------finished processing!!!'
   # sleep(15)
   # puts "producer id #{producer.getProducerID}"
    jms_shutdown(tdest, tconn, tsession, tproducer, tconsumer )
      StompMessage::StompSendTopic.send_email_stomp("scott.sproule@cure.com.ph","STOMP MSG", options[:email],
                      "#{options[:topic]}: #{msg.command}", result) if  options[:email]!=nil
  
    
   # Thread.exit
    exit!
  
