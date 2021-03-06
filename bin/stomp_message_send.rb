#!/usr/bin/env ruby
# == Synopsis
#   Send a message to a stomp server and wait for result if requested
# == Usage
#  stomp_message_send.rb -T topic -M command -b body -h host -p port " 
#   Debug: to turn on debug: stomp_message_send.rb -T '/topic/sms' -M stomp_DEBUG -b nil
#   Statistics:  stomp_message_send.rb -T '/topic/sms' -M stomp_REPORT -b nil -A true
#    Reconnect: stomp_message_send.rb -T '/topic/sms' -M stomp_RECONNECT -b nil -A true  ---- NOT USED OFTEN
# Ping:  for ping test: stomp_message_send.rb -T '/topic/sms' -M stomp_PING -b nil -A true
# Ping: for email ping test: stomp_message_send.rb -T '/topic/sms' -M stomp_PING -b nil -A true -D comma_separated_email_addresses"
# Note -a flag for response  --- eg true or false
# == Useful commands
# stomp_message_send.rb -T '/topic/sms' -M stomp_PING -b nil -A true
# stomp_message_send.rb -T '/topic/sms' -M stomp_DEBUG -b nil
# stomp_message_send.rb -T '/topic/sms' -M stomp_REPORT -b nil -A true -D email@com
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



 arg_hash=StompMessage::Options.parse_options(ARGV)
 RDoc::usage if  arg_hash[:topic]==nil || arg_hash[:command]==nil || arg_hash[:help]==true
require 'pp'
  options = arg_hash
   # set up variables using hash
    msg_sender=StompMessage::StompSendTopic.new(options) 
    msg_sender.jms_set_debug(true) if arg_hash[:debug]
    #msg_sender.setup_auto_close  if !msg_sender.java?
    m=StompMessage::Message.new(options[:command],options[:body])
    puts "message is: #{m.to_xml}"
   # billing_sender.send_topic(m.body,  arg_hash[:msisdn]) 
   # m=StompMessage::Message.new('stomp_BILLING', msg)
     header = {}
     header[:msisdn]=arg_hash[:msisdn]
      msg_received_flag=false
      msg_data=nil
      case options[:ack].downcase
      when   'true'
         msg_data= msg_sender.send_topic_ack(m,header,50)  
      else
          msg_sender.send_topic(m,header)
       
      end
          
     msg_sender.send_email_stomp("scott.sproule@cure.com.ph","STOMP MSG", options[:email],
                    "#{options[:topic]}: #{m.command}", msg_data) if msg_received_flag and options[:email]!=nil
   
     msg_sender.send_topic_jms_shutdown if msg_sender.java?
    
    puts  '-------------finished processing!!!'
    exit!
  
