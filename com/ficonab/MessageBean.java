package com.ficonab;
import javax.jms.MessageListener;
import com.ficonab.FiconabBase;

// @MessageDriven(mappedName = "test")
// @MessageDriven(mappedName = "test")
public class MessageBean  extends FiconabBase  implements MessageListener {
	 	public  String get_topic() { return "test"; }
    public MessageBean()  {}
	public String get_bootstrap_string() {
	
	String bootstrap_string = "gem 'stomp_message'; require 'stomp_message';  StompMessage::StompServer.new({:topic => 'test', :jms_source => 'msgserver'})"; 
	    return bootstrap_string;
	}
	
}