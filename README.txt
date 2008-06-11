= Stomp Message
A basic package for sending and receiving stomp messages

Active Record Server Class

This extends the server class to access active record.  It is based on the rail app structure where the config file has database.yml and the app/models/*.rb contains all the files that are needed for active record.  Note that there is some strange code to pick up class name of last file loaded for checking the AR connection.  THis needs to be fixed.

But in general with the AR Server class you can recieve messages and write them to active record databases.


A server class will listen to topics  (StompMessage::StompServer)


A class to easily send (and receive messages from the server).  Since the messsage protocol is semi one way to receive a message you reply to a distinct topic and a call back is executed.

The code below creates server class and sends message/gets response. 

IMPORTANT apachemq or some other messaging platform must be running :)

 args={:topic => '/topic/test'}
 ss=StompMessage::StompStatisticsServer.new(args)
 ss_thread = Thread.new {
        ss.run }
 
 msg=StompMessage::Message.new('stomp_REPORT', "body")

 puts "creating send topic"
 send_topic=StompMessage::StompSendTopic.new(args)
  send_topic.send_topic_acknowledge(msg,{ :msisdn => "639999"})   { |m| 
                puts "#{m.to_s}"
                msg=StompMessage::Message.load_xml(m)
                assert msg.command== 'stomp_REPLY',  "command wrong"
                }

JRUBY
Scotts-Computer:~/Documents/ror/checkouts/stomp_message scott$ cp /Users/scott/Documents/ror/glassfish/jruby/jruby-1_0_3/jruby-1.0.3/lib/asm-
asm-2.2.3.jar          asm-commons-2.2.3.jar  
Scotts-Computer:~/Documents/ror/checkouts/stomp_message scott$ cp /Users/scott/Documents/ror/glassfish/jruby/jruby-1_0_3/jruby-1.0.3/lib/asm*.jar build
Scotts-Computer:~/Documents/ror/checkouts/stomp_message scott$ cp /Users/scott/Documents/ror/glassfish/jruby/jruby-1_0_3/jruby-1.0.3/lib/backport-util-concurrent.jar build
Scotts-Computer:~/Documents/ror/checkouts/stomp_message scott$ cp /Users/scott/Documents/ror/glassfish/jruby/jruby-1_0_3/jruby-1.0.3/lib/jline-0.9.91.jar build
Scotts-Computer:~/Documents/ror/checkouts/stomp_message scott$ cp /Users/scott/Documents/ror/glassfish/jruby/jruby-1_0_3/jruby-1.0.3/lib/jruby build
jruby-complete.jar  jruby.jar           
Scotts-Computer:~/Documents/ror/checkouts/stomp_message scott$ cp /Users/scott/Documents/ror/glassfish/jruby/jruby-1_0_3/jruby-1.0.3/lib/jruby.jar build
Scotts-Computer:~/Documents/ror/checkouts/stomp_message scott$ cp /Users/scott/Documents/ror/glassfish/jruby/jruby-1_0_3/jruby-1.0.3/lib/mysql-connector-java-5.0.8-bin.jar build
Scotts-Computer:~/Documents/ror/checkouts/stomp_message scott$ ls build
asm-2.2.3.jar                           jline-0.9.91.jar
asm-commons-2.2.3.jar                   jruby.jar
backport-util-concurrent.jar            mysql-connector-java-5.0.8-bin.jar
com
BUILD JAR FILE
 cd build
 jar cf ../ficonab.jar .

#COMPILING:
 javac -cp $JRUBY_HOME/lib/jruby.jar:$GLASSFISH_ROOT/lib/j2ee.jar -d build com/ficonab/FiconabBase.java
 javac -cp $JRUBY_HOME/lib/jruby.jar:$GLASSFISH_ROOT/lib/j2ee.jar:./build -d build com/ficonab/MessageBean.java
#BUILD JAR FILE
 cd build
 jar cf ../ficonab.ear .
#INSTALL
 cd ..
 asadmin deploy ficonab.ear
asadmin deploy --host svbalance.cure.com.ph --port 2626 ficonab.ear

AUTODEPLOY
 cp ficonab.jar ../../glassfish/domains/domain1/autodeploy/


war file.
jar cf smsapp.war -C tmp/war .

jar cf ../ficonab.jar .

IMPORTANT
Jdbc pools must be non transactional and set to allow non component callers.



CLASSPATHS
export CLASSPATH=$CLASSPATH:$GLASSFISH_ROOT/lib/j2ee.jar
export CLASSPATH=$CLASSPATH:$GLASSFISH_ROOT/lib/appserv-rt.jar
export CLASSPATH=$CLASSPATH:$GLASSFISH_ROOT/lib/javaee.jar
export CLASSPATH=$CLASSPATH:$GLASSFISH_ROOT/lib/j2ee-svc.jar
export CLASSPATH=$CLASSPATH:$GLASSFISH_ROOT/lib/appserv-ee.jar
export CLASSPATH=$CLASSPATH:$GLASSFISH_ROOT/lib/activation.jar
export CLASSPATH=$CLASSPATH:$GLASSFISH_ROOT/lib/dbschema.jar 
export CLASSPATH=$CLASSPATH:$GLASSFISH_ROOT/lib/appserv-admin.jar 
export CLASSPATH=$CLASSPATH:$GLASSFISH_ROOT/lib/install/applications/jmsra/imqjmx.jar   
export CLASSPATH=$CLASSPATH:$GLASSFISH_ROOT/lib/install/applications/jmsra/imqjmsra.jar

 export CLASSPATH=$CLASSPATH:$GLASSFISH_ROOT/imq/lib/fscontext.jar


Filesystem context:

CLASSPATH=/Users/scott/Documents/ror/glassfish/lib/install/jmsra/imqjsra.jar:/Users/scott/Documents/ror/glassfish/lib/j2ee.jar:/Users/scott/Documents/ror/glassfish/lib/appserv-rt.jar:/Users/scott/Documents/ror/glassfish/lib/javaee.jar:/Users/scott/Documents/ror/glassfish/lib/j2ee-svc.jar:/Users/scott/Documents/ror/glassfish/lib/appserv-ee.jar:/Users/scott/Documents/ror/glassfish/lib/install/applications/jmsra/imqjmsra.jar:/Users/scott/Documents/ror/glassfish/lib/install/applications/jmsra/imqjmx.jar:/Users/scott/Documents/ror/glassfish/lib/install/applications/jmsra/imqbroker.jar:/Users/scott/Documents/ror/glassfish/lib/dbschema.jar:/Users/scott/Documents/ror/glassfish/lib/appserv-admin.jar



