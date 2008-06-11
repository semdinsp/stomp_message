package com.ficonab;

import javax.jms.Message;
import javax.jms.MessageListener;
import javax.annotation.Resource;
import javax.ejb.MessageDriven;
import javax.ejb.MessageDrivenContext;

import java.io.PrintStream;
import java.io.IOException;
import java.io.FileOutputStream;

import java.util.List;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.Map;
import java.util.HashMap;

import javax.annotation.PostConstruct;
import javax.annotation.PreDestroy;

import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyHash;
import org.jruby.RubyClass;
import org.jruby.RubyException;
import org.jruby.RubyKernel;
import org.jruby.RubyString;
import org.jruby.runtime.builtin.IRubyObject;
import org.jruby.runtime.Block;
import org.jruby.javasupport.JavaUtil;
import org.jruby.exceptions.RaiseException;
import org.jruby.javasupport.JavaEmbedUtils;
import javax.jms.ConnectionFactory;
import javax.annotation.Resource;

// @MessageDriven(mappedName = "test")
// @MessageDriven(mappedName = "test")
public class FiconabBase {
	 
	  private Ruby engine;
	//  private RubyClass engineClass;
	//  private RubyClass serverClass;
// 	 private static int instancecount=0;  NO static variables
	 private IRubyObject engineInstance;
	  private PrintStream out;
// public void ejbCreate()  {
		//	  	out.println("ejbCREATE starting up: calling create_jms_mdb_connections" + get_topic());
					//	 IRubyObject atemp;
					//	 atemp=null;
	//					 IRubyObject[] atemparray= new IRubyObject[]{};
	//		      JavaEmbedUtils.invokeMethod( this.engine, this.engineInstance, "create_jms_mdb_connections", atemparray, null );   
//		}
	@PreDestroy public void destruct() throws IOException {
		  	out.println("PREDESTROY shutting down:" + get_topic());
				//	 IRubyObject atemp;
				//	 atemp=null;
					 IRubyObject[] atemparray= new IRubyObject[]{};
		      JavaEmbedUtils.invokeMethod( this.engine, this.engineInstance, "jms_close_connections", atemparray, null );   
		out.println("PREDESTROY after jms_close_connections: " + get_topic());
		// JavaEmbedUtils.invokeMethod( this.engine, this.engineInstance, "exit!", atemparray, null );
		 atemparray=null;
		 	out.println("DEAD: " + get_topic() + " :closing variables and exitting mdb.");
		 out.close();
		 out=null;
		// instancecount=instancecount-1;
		this.engineInstance= null;
		// new to try to speed it up
	  	JavaEmbedUtils.terminate(this.engine);
		// this.engine.tearDown();
		 this.engine= null;
	}
	public  String get_topic() { return "bod_base_topic"; }
	public String get_bootstrap_string() {
	String bootstrap_string = "puts 'WRONG BOOTSTRAP STRING'"; 
	    return bootstrap_string;
	}
	// JRUBY HOME SHOULD BE SET
	
	@PostConstruct public void init() throws IOException {
	//	String jruby_home = "/Users/scott/Documents/ror/glassfish/jruby/jruby-1_0_3/jruby-1.0.3";
	  String jruby_home= System.getenv("JRUBY_HOME");
	 // instancecount=instancecount+1;
		out = new PrintStream( new FileOutputStream(jruby_home + "/log/"+ get_topic() +".log"));
		out.println("STARTING MESSAGE BEAN for: " + get_topic() );
		out.println("jruby home:" + jruby_home);
		System.setProperty("jruby.home",jruby_home);
		System.setProperty("jruby.thread.pooling","true");
		System.setProperty("jruby.base",jruby_home);
		System.setProperty("jruby.lib",jruby_home+ "/lib");
		System.setProperty("jruby.script","jruby");
		System.setProperty("jruby.shell","/bin/sh");
		this.engine=Ruby.newInstance(System.in,out,out);
		List loadPaths=new ArrayList();
		String lp = jruby_home + "/lib";
		loadPaths.add(lp);
		this.engine.getLoadService().init(loadPaths);
	  	 RubyKernel.require(engine.getModule("Kernel"), engine.newString("rubygems"), Block.NULL_BLOCK);
		 	// String expr = "gem 'stomp_message' \nrequire 'stomp_message'\n StompMessage::StompServer.class";
		// this.engineClass = (org.jruby.RubyClass)engine.evalScript(expr);
	  //	this.engineClass=this.engine.getClass("StompServer");
	 // if (this.engineClass==null) { out.println("engine class null"); }
	      String bootstrap_string=this.get_bootstrap_string();
	      this.engineInstance = JavaEmbedUtils.newRuntimeAdapter().eval( this.engine, bootstrap_string );
		
	}
	private RubyHash buildPropertyHash(javax.jms.TextMessage msg)  {
        Map val = new HashMap();
        try {
        for(java.util.Enumeration iter = msg.getPropertyNames();iter.hasMoreElements();) {
            String propname = (String)iter.nextElement();
            try{
	               String propvalue= msg.getStringProperty(propname);
	               IRubyObject v =  this.engine.newString(propvalue) ;
              	 IRubyObject k =  this.engine.newString(propname) ;
	               val.put(k, v);
	             //  out.println("iterator"+propname+":"+propvalue);
             }
              catch (javax.jms.JMSException e)
									{
	                    // try for int?
										}
               
            }
          }
             catch (javax.jms.JMSException e)
									{
	                   out.println("BUG no properties for message");
										}
      
        return RubyHash.newHash(this.engine, val, this.engine.getNil());
	}
	private void callRubyMessage(javax.jms.TextMessage msg) {
		 IRubyObject msg_body, msg_hash;
		 msg_body=null;
		 msg_hash=null;
		 try {
		 if (msg.getText()!=null)   { msg_body= this.engine.newString(msg.getText()) ; }
		 else {msg_body = this.engine.getNil(); }
	
		   msg_hash = buildPropertyHash(msg) ;
	   }
	    catch (javax.jms.JMSException e)   { }
	 IRubyObject[] temparray= new IRubyObject[]{msg_body, msg_hash};  // arguements to call onMessage
	//	 IRubyObject serverInstance = this.engineClass.callMethod( this.engine.getCurrentContext(), "new", temparray);
		  JavaEmbedUtils.invokeMethod( this.engine, this.engineInstance, "onMessage", temparray, null );
		    temparray=null;
//		 IRubyObject res = serverInstance.callMethod(this.engine.getCurrentContext(), "onMessage", temparray );
		     
	}
	public void setMessageDrivenContext(MessageDrivenContext context) {
	  this.mdc = context; 
	 //   System.out.println("setMessageDrivenContext"); 
	  }
	@Resource private MessageDrivenContext mdc;
	public FiconabBase() { }
	public void onMessage(Message msg)  {    javax.jms.TextMessage tmsg=(javax.jms.TextMessage) msg;
		                                       //out.print("hello\n");
		                                      // try {  // String body= tmsg.getText();
	                                                //out.print(body);
	                                                this.callRubyMessage(tmsg);
	                                          //   }
	                                        // catch (javax.jms.JMSException e)  {
		                                        //      out.print("exception found");
	                                           //   }
	           }
}