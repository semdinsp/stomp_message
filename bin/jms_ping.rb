#!/usr/bin/env jruby -S
# == Synopsis
#   Send a  ping message to a jms server and wait for result 
# == Usage
#  jms_ping.rb -T topic -d " 
# Ping:  for ping test: stomp_message_send.rb -T '/topic/sms' -M stomp_PING -b nil -A true
# Ping: for email ping test: stomp_message_send.rb -T '/topic/sms' -M stomp_PING -b nil -A true -D comma_separated_email_addresses"
# Note -a flag for response  --- eg true or false
# == Useful commands
#  jruby -S jms_ping.rb  -T sms
#  jruby -S jms_ping   -d  -T sms
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
   # set up variables using hash
   
   jms_start("TopicConnectionFactory")
   jms_set_debug(arg_hash[:debug])
   tdest, tconn= jms_create_destination_connection( arg_hash[:topic])
   tproducer, tsession= jms_create_producer_session(tdest,tconn)
   tconsumer, consumer_session = jms_create_consumer_session(tdest,tconn) 
   msg=StompMessage::Message.new('stomp_PING',"#{Time.now}")
  # msg=StompMessage::Message(arg_hash[:command],'hello body there')
 
     result =jms_send_ack(tsession,tproducer,msg.to_xml) 
  #   consumer_session.close
     puts "#{result}"
 #  sleep(1)
   
  
    
    puts  '-------------finished processing!!!'
   # sleep(15)
   # puts "producer id #{producer.getProducerID}"
    jms_shutdown(tdest, tconn, tsession, tproducer, tconsumer )
     
    
   # Thread.exit
    exit!
  
