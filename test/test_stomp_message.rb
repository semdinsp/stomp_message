require File.dirname(__FILE__) + '/test_helper.rb'
 
 require 'rubygems'

 gem 'stomp_message'
 require 'stomp_message'
class TestStompMessage < Test::Unit::TestCase

  def setup
  end
  
  def test_object_create
    m1=StompMessage::Message.new("command")
     m2=StompMessage::Message.new("command")
     assert m1.to_xml==m2.to_xml, "xml generation wrong"
  end
  def test_object_create2
    m1=StompMessage::Message.new("command",true)
     m2=StompMessage::Message.new("command",true)
     assert m1.to_xml==m2.to_xml, "xml generation wrong"
       m1=StompMessage::Message.new("command",false)
        m2=StompMessage::Message.new("command",false)
        assert m1.to_xml==m2.to_xml, "xml generation wrong"
  end
  def test_xml_helper_load_iv
     m1=StompMessage::Message.new("command",true)
      m2=StompMessage::Message.new("command",true)
      assert m1.to_xml==m2.to_xml, "xml generation wrong"
        m3=StompMessage::Message.load_xml_new(m2.to_xml)
        puts "M3 is #{m3.to_xml}"
        assert m3.class=StompMessage::Message, 'm3 is wrong'
     assert m3.to_xml==m2.to_xml, "xml generation wrong"
      assert m3.to_xml==m1.to_xml, "xml generation wrong"
   end
  def test_object_nil
     begin
     m1=StompMessage::Message.new(nil)
   rescue Exception => e
      assert true, 'raised exception'
     end
   end
    class M3 < StompMessage::Message
      attr_accessor :msisdns, :bad , :s
      def initialize(cmd)
        super(cmd)
        self.msisdns=[]
         self.s= []
        self.bad = []
        self.msisdns << "test"
         self.msisdns << "test2"
        self.bad << "test"
         self.s << "test"
      end
    end  # class M3
      class M4 < StompMessage::Message
        attr_accessor :msisdns
        def initialize(cmd)
          super(cmd, "body")
          self.msisdns=[]
          self.msisdns << "test"
           self.msisdns << "test2"
        end
      end  # class M3
   def test_xml1_helper
       puts "XML Helper test"
       m2=M3.new("command")
       begin
         res=m2.to_xml
        # puts "m2 xml is #{res}"
       rescue Exception => e
         puts "found exception #{e.message}"
         assert e.message=="not terminate in s or too short", "bad message"
       end
     end
      def test_xml2_helper
          puts "XML2 Helper test"
          m2=M4.new("command")
          begin
            res=m2.to_xml
            puts "m2 xml is #{res}"
          rescue Exception => e
            puts "found exception #{e.message}"
            assert false, "bad message #{e.message}"
          end
          
        end
  def test_object_duplication
     m1=StompMessage::Message.new("command")
     m2=StompMessage::Message.new("command")
     m3=StompMessage::Message.load_xml(m2.to_xml)
     assert m1.to_xml==m2.to_xml, "xml generation wrong"
     assert m3.to_xml==m2.to_xml, "xml generation wrong"
      m2=StompMessage::Message.new("command","body")
       assert m3.to_xml!=m2.to_xml, "xml generation wrong"  
      m4=StompMessage::Message.load_xml(m2.to_xml)
      puts "CHECK THIS m2 is: #{m2.to_xml} m4 is #{m4.to_xml}"
      assert m4.body==m2.body, "xml generation wrong"
  end
  def test_statistics_server
    #note activemq or stomp message bus needs to be running
     args={:topic => '/topic/test'}
     ss=StompMessage::StompStatisticsServer.new(args)
     ss_thread = Thread.new {
            ss.run }
     assert ss.topic=='/topic/test', "topic not set properly"
     sleep(1)
     msg=StompMessage::Message.new('stomp_REPORT', "body")
     assert msg.command=='stomp_REPORT', "message command not correct"
     puts "creating send topic"
     send_topic=StompMessage::StompSendTopic.new(args)
     puts "send topic NO ack"
     send_topic.send_topic(msg,{ :msisdn => "639999"})
      puts "send topic WITH ack"
      msg_reply=''
    send_topic.send_topic_acknowledge(msg,{ :msisdn => "639999"})   { |m|  assert true
                    puts "#{m.to_s}"
                    msg_reply=StompMessage::Message.load_xml(m)
                
                  }
        sleep(3)
          assert msg_reply.command== 'stomp_REPLY',  "command wrong"    
      ss_thread.kill          
  end
  def test_base_server
    #note activemq or stomp message bus needs to be running
     args={:topic => '/topic/test'}
     ss=StompMessage::StompServer.new(args)
     ss_thread = Thread.new {
            ss.run }
     sleep(3)
     assert ss.topic=='/topic/test', "topic not set properly"
     msg=StompMessage::Message.new('stomp_PING', "body")
     assert msg.command=='stomp_PING', "message command not correct"
     puts "creating ping messager topic"
     send_topic=StompMessage::StompSendTopic.new(args) 
      puts "send ping WITH ack"
      msg_reply=''
       send_topic.send_topic_acknowledge(msg,{ :msisdn => "639999"})   { |m|  assert true
                    puts "#{m.to_s}"
                    msg_reply=StompMessage::Message.load_xml(m)
                    assert msg_reply.body.split[0]== 'ALIVE',  "ping not ok #{msg_reply.body}" 
                  }
        sleep(3)
          assert msg_reply.command== 'stomp_REPLY',  "command wrong" 
          send_topic.close_topic   
      ss_thread.kill          
  end
  def test_statistics_reset
    #note activemq or stomp message bus needs to be running
     args={:topic => '/topic/test'}
     ss=StompMessage::StompStatisticsServer.new(args)
     ss_thread = Thread.new {
            ss.run }
     assert ss.topic=='/topic/test', "topic not set properly"
     msg=StompMessage::Message.new('stomp_REPORT', "body")
     assert msg.command=='stomp_REPORT', "message command not correct"
     puts "creating send topic"
     send_topic=StompMessage::StompSendTopic.new(args)
     puts "send topic NO ack"
     send_topic.send_topic(msg,{ :msisdn => "639999"})
      puts "send topic WITH ack"
      msg_reply = ""
      send_topic.setup_auto_close
    send_topic.send_topic_acknowledge(msg,{ :msisdn => "639999"})   { |m|  assert true
                    puts "#{m.to_s}"
                    msg_reply=StompMessage::Message.load_xml(m)

                    }
                    sleep(3)
     assert msg_reply.command== 'stomp_REPLY',  "command wrong"
   send_topic.send_topic_acknowledge(msg,{ :msisdn => "639999"})   { |m|  assert true
                         puts "#{m.to_s}"
                          msg_reply=StompMessage::Message.load_xml(m)

                                    }
                  sleep(3)
              assert msg_reply.command== 'stomp_REPLY',  "command wrong"
              response = msg_reply.body.to_s
              assert response.include?("stomp_REPORT: 3"),  "Stomp_Report 3 not included"
              assert !response.to_s.include?("stomp_REPORT: 0"),  "Stomp_Report: 0  included"
                          # reset hour statistics
                 msg2=StompMessage::Message.new('stomp_RESET', "hour")
                 assert msg2.command=='stomp_RESET', "message command not correct"
                 puts "creating send msg2 topic"
                       send_topic.send_topic(msg2,{ :msisdn => "639999"})                             
            send_topic.send_topic_acknowledge(msg,{ :msisdn => "639999"})   { |m|  assert true
                                                           puts "#{m.to_s}"
                                    msg_reply=StompMessage::Message.load_xml(m)
                                 
                                                                      }   
                                sleep(3)
                       assert msg_reply.command== 'stomp_REPLY',  "command wrong"
                                    response = msg_reply.body.to_s
                assert response.include?("stomp_REPORT: 1"),  "Stomp_Report 0 not included"
              assert response.include?("stomp_RESET: 1"),  "Stomp_RESET 1 not included"
                assert !response.to_s.include?("stomp_REPORT: 2"),  "Stomp_Report: 2  included" 
          ss_thread.kill                           
  end
  
  
end
