#!/usr/bin/env ruby
# == Synopsis
# jruby -S jms_server_standalone.rb -T topic
#   start up the server standalone.  This is the key component for listening to subscription message
# == Usage
#   jruby -S jms_server_standalone.rb -T test
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
 # env_setting = ARGV[1] || "production"
 #   path_setting = ARGV[0] || "/opt/local/rails_apps/subscriptions/current/"
  arg_hash=StompMessage::Options.parse_options(ARGV)
  RDoc::usage if  arg_hash[:topic]==nil || arg_hash[:help]==true
 require 'pp'
   options = arg_hash
 @my_topic = arg_hash[:topic]
    # set up variables using hash

    jms_start("TopicConnectionFactory")
    jms_set_debug(arg_hash[:debug])
    tdest, tconn= jms_create_destination_connection( arg_hash[:topic])
    tproducer, tsession= jms_create_producer_session(tdest,tconn)
    tconsumer, consumer_session = jms_create_consumer_session(tdest,tconn) 
    
  #  begin
      topic=arg_hash[:topic]
      s=StompMessage::StompServer.new({:topic => "#{topic}", :standalone => 'true', :jms_source => 'msgserver'}) 
        tlistener=StompMessage::MySpecialListener.new(s)
        tconsumer.setMessageListener(tlistener)
       #.run
   #   sms_listener.join
   # rescue Exception => e
    #  puts "exception found #{e.backtrace}" 
  #  end
   
   
    
